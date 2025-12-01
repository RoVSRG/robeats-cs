#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Types for Roblox instance metadata
type UDim2 = [[number, number], [number, number]]; // [[scaleX, offsetX], [scaleY, offsetY]]
type UDim = [number, number]; // [scale, offset]
type Color3 = [number, number, number]; // [R, G, B]

interface MetaJson {
  className?: string;
  properties?: {
    Size?: { UDim2: UDim2 } | UDim2;
    Position?: { UDim2: UDim2 } | UDim2;
    AnchorPoint?: [number, number];
    BackgroundColor3?: Color3;
    TextColor3?: Color3;
    Font?: { Enum: number } | number;
    TextSize?: number;
    Text?: string;
    PlaceholderText?: string;
    BorderSizePixel?: number;
    BackgroundTransparency?: number;
    TextTransparency?: number;
    Visible?: boolean;
    ZIndex?: number;
    LayoutOrder?: number;
    // UIListLayout specific
    FillDirection?: { Enum: number } | number;
    HorizontalAlignment?: { Enum: number } | number;
    VerticalAlignment?: { Enum: number } | number;
    Padding?: { UDim2: UDim2 } | UDim2;
    SortOrder?: { Enum: number } | number;
    Wraps?: boolean;
    [key: string]: any;
  };
}

interface InstanceNode {
  name: string;
  className: string;
  path: string;
  properties: MetaJson['Properties'];
  children: InstanceNode[];
}

interface LayoutSpec {
  name: string;
  className: string;
  path: string;
  parent?: string;
  size?: {
    width: { scale: number; offset: number };
    height: { scale: number; offset: number };
  };
  position?: {
    x: { scale: number; offset: number };
    y: { scale: number; offset: number };
  };
  anchorPoint?: { x: number; y: number };
  color?: string;
  textColor?: string;
  fontSize?: number;
  text?: string;
  visible?: boolean;
  zIndex?: number;
  backgroundTransparency?: number;
  borderSizePixel?: number;
  children?: string[];
  // UIListLayout specific
  fillDirection?: string;
  horizontalAlignment?: string;
  verticalAlignment?: string;
  padding?: { scale: number; offset: number };
  sortOrder?: string;
  wraps?: boolean;
  // UIPadding specific
  paddingTop?: { scale: number; offset: number };
  paddingBottom?: { scale: number; offset: number };
  paddingLeft?: { scale: number; offset: number };
  paddingRight?: { scale: number; offset: number };
  // UICorner specific
  cornerRadius?: { scale: number; offset: number };
}

// Helper to unwrap UDim2 from wrapper object
function unwrapUDim2(value: { UDim2: UDim2 } | UDim2 | undefined): UDim2 | undefined {
  if (!value) return undefined;
  if ('UDim2' in value) return value.UDim2;
  return value as UDim2;
}

// Helper to unwrap UDim from wrapper object
function unwrapUDim(value: { UDim: UDim } | UDim | undefined): UDim | undefined {
  if (!value) return undefined;
  if ('UDim' in value) return value.UDim;
  return value as UDim;
}

// Helper to unwrap Enum from wrapper object
function unwrapEnum(value: { Enum: number } | number | undefined): number | undefined {
  if (value === undefined) return undefined;
  if (typeof value === 'object' && 'Enum' in value) return value.Enum;
  return value as number;
}

// Helper to format UDim2 as readable string
function formatUDim2(udim: { UDim2: UDim2 } | UDim2 | undefined, axis: 'X' | 'Y'): string {
  const unwrapped = unwrapUDim2(udim);
  if (!unwrapped) return '0';
  const [scale, offset] = axis === 'X' ? unwrapped[0] : unwrapped[1];

  if (scale === 0) return `${offset}px`;
  if (offset === 0) return `${(scale * 100).toFixed(1)}%`;
  return `${(scale * 100).toFixed(1)}% + ${offset}px`;
}

// Helper to format Color3
function formatColor3(color: Color3 | undefined): string {
  if (!color) return '';
  // Color3 values are 0-1 range, need to scale to 0-255
  return `Color3.fromRGB(${Math.round(color[0] * 255)}, ${Math.round(color[1] * 255)}, ${Math.round(color[2] * 255)})`;
}

// Helper to convert FillDirection enum to string
function fillDirectionToString(value: number | undefined): string | undefined {
  if (value === undefined) return undefined;
  const directions = ['Horizontal', 'Vertical'];
  return directions[value] || 'Horizontal';
}

// Helper to convert HorizontalAlignment enum to string
function horizontalAlignmentToString(value: number | undefined): string | undefined {
  if (value === undefined) return undefined;
  const alignments = ['Center', 'Left', 'Right'];
  return alignments[value] || 'Center';
}

// Helper to convert VerticalAlignment enum to string
function verticalAlignmentToString(value: number | undefined): string | undefined {
  if (value === undefined) return undefined;
  const alignments = ['Center', 'Top', 'Bottom'];
  return alignments[value] || 'Center';
}

// Helper to convert SortOrder enum to string
function sortOrderToString(value: number | undefined): string | undefined {
  if (value === undefined) return undefined;
  const orders = ['Name', 'Custom', 'LayoutOrder'];
  return orders[value] || 'LayoutOrder';
}

// Parse a directory into an InstanceNode tree
async function parseDirectory(dirPath: string, name: string = ''): Promise<InstanceNode | null> {
  const metaPath = path.join(dirPath, 'init.meta.json');
  let meta: MetaJson = {};

  try {
    const metaContent = await fs.readFile(metaPath, 'utf-8');
    meta = JSON.parse(metaContent);
  } catch (err) {
    // No meta file, might be a folder-only structure
  }

  const node: InstanceNode = {
    name: name || path.basename(dirPath),
    className: meta.className || 'Folder',
    path: dirPath,
    properties: meta.properties || {},
    children: [],
  };

  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.name === 'init.meta.json' || entry.name.endsWith('.lua') || entry.name.endsWith('.client.lua')) {
        continue; // Skip meta files and script files
      }

      if (entry.isDirectory()) {
        const child = await parseDirectory(path.join(dirPath, entry.name), entry.name);
        if (child) {
          node.children.push(child);
        }
      }
    }
  } catch (err) {
    // Directory read failed
  }

  return node;
}

// Extract layout specs from instance tree
function extractLayoutSpecs(node: InstanceNode, specs: LayoutSpec[] = [], parentName?: string): LayoutSpec[] {
  const props = node.properties;

  const uiElements = ['Frame', 'TextLabel', 'TextButton', 'ImageLabel', 'ImageButton', 'TextBox', 'ScrollingFrame'];
  const layoutConstraints = ['UIListLayout', 'UIPadding', 'UICorner', 'UIFlexItem'];

  // Extract UI elements
  if (uiElements.includes(node.className)) {
    const size = unwrapUDim2(props.Size);
    const position = unwrapUDim2(props.Position);

    const spec: LayoutSpec = {
      name: node.name,
      className: node.className,
      path: node.path,
      parent: parentName,
      size: size ? {
        width: { scale: size[0][0], offset: size[0][1] },
        height: { scale: size[1][0], offset: size[1][1] },
      } : undefined,
      position: position ? {
        x: { scale: position[0][0], offset: position[0][1] },
        y: { scale: position[1][0], offset: position[1][1] },
      } : undefined,
      children: node.children
        .filter(c => uiElements.includes(c.className) || layoutConstraints.includes(c.className))
        .map(c => c.name),
    };

    if (props.AnchorPoint) {
      spec.anchorPoint = { x: props.AnchorPoint[0], y: props.AnchorPoint[1] };
    }
    if (props.BackgroundColor3) {
      spec.color = formatColor3(props.BackgroundColor3);
    }
    if (props.TextColor3) {
      spec.textColor = formatColor3(props.TextColor3);
    }
    if (props.TextSize) {
      spec.fontSize = props.TextSize;
    }
    if (props.Text) {
      spec.text = props.Text;
    }
    if (props.Visible !== undefined) {
      spec.visible = props.Visible;
    }
    if (props.ZIndex !== undefined) {
      spec.zIndex = props.ZIndex;
    }
    if (props.BackgroundTransparency !== undefined) {
      spec.backgroundTransparency = props.BackgroundTransparency;
    }
    if (props.BorderSizePixel !== undefined) {
      spec.borderSizePixel = props.BorderSizePixel;
    }

    specs.push(spec);
  }
  // Extract UIListLayout
  else if (node.className === 'UIListLayout') {
    // Padding for UIListLayout is a UDim (single dimension), not UDim2
    const paddingRaw = props.Padding as any;
    let padding: { scale: number; offset: number } | undefined;

    if (paddingRaw) {
      if ('UDim2' in paddingRaw) {
        // It's wrapped as UDim2, use first component
        padding = { scale: paddingRaw.UDim2[0][0], offset: paddingRaw.UDim2[0][1] };
      } else if (Array.isArray(paddingRaw)) {
        // It's a raw UDim [scale, offset]
        padding = { scale: paddingRaw[0], offset: paddingRaw[1] };
      }
    }

    const spec: LayoutSpec = {
      name: node.name,
      className: node.className,
      path: node.path,
      parent: parentName,
      fillDirection: fillDirectionToString(unwrapEnum(props.FillDirection)),
      horizontalAlignment: horizontalAlignmentToString(unwrapEnum(props.HorizontalAlignment)),
      verticalAlignment: verticalAlignmentToString(unwrapEnum(props.VerticalAlignment)),
      padding,
      sortOrder: sortOrderToString(unwrapEnum(props.SortOrder)),
      wraps: props.Wraps,
    };

    specs.push(spec);
  }
  // Extract UIPadding
  else if (node.className === 'UIPadding') {
    const paddingTop = unwrapUDim(props.PaddingTop as any);
    const paddingBottom = unwrapUDim(props.PaddingBottom as any);
    const paddingLeft = unwrapUDim(props.PaddingLeft as any);
    const paddingRight = unwrapUDim(props.PaddingRight as any);

    const spec: LayoutSpec = {
      name: node.name,
      className: node.className,
      path: node.path,
      parent: parentName,
      paddingTop: paddingTop ? { scale: paddingTop[0], offset: paddingTop[1] } : undefined,
      paddingBottom: paddingBottom ? { scale: paddingBottom[0], offset: paddingBottom[1] } : undefined,
      paddingLeft: paddingLeft ? { scale: paddingLeft[0], offset: paddingLeft[1] } : undefined,
      paddingRight: paddingRight ? { scale: paddingRight[0], offset: paddingRight[1] } : undefined,
    };

    specs.push(spec);
  }
  // Extract UICorner
  else if (node.className === 'UICorner') {
    const cornerRadius = unwrapUDim(props.CornerRadius as any);

    const spec: LayoutSpec = {
      name: node.name,
      className: node.className,
      path: node.path,
      parent: parentName,
      cornerRadius: cornerRadius ? { scale: cornerRadius[0], offset: cornerRadius[1] } : undefined,
    };

    specs.push(spec);
  }

  for (const child of node.children) {
    extractLayoutSpecs(child, specs, node.name);
  }

  return specs;
}

// Generate ASCII hierarchy tree
function generateHierarchy(node: InstanceNode, indent: string = '', isLast: boolean = true): string {
  const props = node.properties;
  let line = indent;

  if (indent) {
    line += isLast ? '└─ ' : '├─ ';
  }

  line += `${node.name}`;

  // Add relevant info
  const info: string[] = [];
  if (props.Size) {
    info.push(`${formatUDim2(props.Size, 'X')} × ${formatUDim2(props.Size, 'Y')}`);
  }
  if (node.className !== 'Frame' && node.className !== 'Folder') {
    info.push(node.className);
  }

  if (info.length > 0) {
    line += ` (${info.join(', ')})`;
  }

  line += '\n';

  const newIndent = indent + (isLast ? '   ' : '│  ');
  for (let i = 0; i < node.children.length; i++) {
    const child = node.children[i];
    const childIsLast = i === node.children.length - 1;
    line += generateHierarchy(child, newIndent, childIsLast);
  }

  return line;
}

// Main parsing function
async function parseArchive(screenName: string) {
  const archivePath = path.join(__dirname, '..', 'archive_screens', screenName);
  const outputPath = path.join(__dirname, '..', 'archive-parsed', screenName);

  console.log(`Parsing ${screenName}...`);

  try {
    await fs.access(archivePath);
  } catch {
    console.error(`❌ Archive not found: ${archivePath}`);
    return;
  }

  // Parse the archive directory
  const tree = await parseDirectory(archivePath, screenName);
  if (!tree) {
    console.error(`❌ Failed to parse archive`);
    return;
  }

  // Create output directory
  await fs.mkdir(outputPath, { recursive: true });

  // 1. Generate hierarchy diagram
  const hierarchy = generateHierarchy(tree);
  await fs.writeFile(path.join(outputPath, 'hierarchy.txt'), hierarchy);
  console.log(`✅ Generated hierarchy.txt`);

  // 2. Extract layout specs
  const specs = extractLayoutSpecs(tree);
  const specsJson = JSON.stringify(specs, null, 2);
  await fs.writeFile(path.join(outputPath, 'layout-specs.json'), specsJson);
  console.log(`✅ Generated layout-specs.json (${specs.length} components)`);

  // 3. Generate summary
  const summary = `# ${screenName} Archive Parse Summary

## Structure
${hierarchy}

## Statistics
- Total UI elements: ${specs.length}
- Frames: ${specs.filter(s => s.className === 'Frame').length}
- TextLabels: ${specs.filter(s => s.className === 'TextLabel').length}
- TextButtons: ${specs.filter(s => s.className === 'TextButton').length}
- ScrollingFrames: ${specs.filter(s => s.className === 'ScrollingFrame').length}

## Key Components
${specs.filter(s => s.size && s.position).slice(0, 10).map(s => {
  const width = s.size!.width.scale > 0
    ? `${(s.size!.width.scale * 100).toFixed(1)}%${s.size!.width.offset !== 0 ? ` + ${s.size!.width.offset}px` : ''}`
    : `${s.size!.width.offset}px`;
  const height = s.size!.height.scale > 0
    ? `${(s.size!.height.scale * 100).toFixed(1)}%${s.size!.height.offset !== 0 ? ` + ${s.size!.height.offset}px` : ''}`
    : `${s.size!.height.offset}px`;
  const x = s.position!.x.scale > 0
    ? `${(s.position!.x.scale * 100).toFixed(1)}%${s.position!.x.offset !== 0 ? ` + ${s.position!.x.offset}px` : ''}`
    : `${s.position!.x.offset}px`;
  const y = s.position!.y.scale > 0
    ? `${(s.position!.y.scale * 100).toFixed(1)}%${s.position!.y.offset !== 0 ? ` + ${s.position!.y.offset}px` : ''}`
    : `${s.position!.y.offset}px`;
  return `- **${s.name}** (${s.className}): ${width} × ${height} at (${x}, ${y})`;
}).join('\n')}

---
Generated: ${new Date().toISOString()}
`;
  await fs.writeFile(path.join(outputPath, 'README.md'), summary);
  console.log(`✅ Generated README.md`);

  console.log(`\n✨ Done! Output saved to: ${outputPath}`);
}

// Main entry point
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log('Usage: npm run parse <screen-name>');
    console.log('Example: npm run parse SongSelect');
    process.exit(1);
  }

  const screenName = args[0];
  await parseArchive(screenName);
}

main().catch(console.error);
