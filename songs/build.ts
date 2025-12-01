import fs from "fs";
import path from "path";
import pako from "pako";

const SONGS_DB_DIR = path.join("songs", "db");
const DIST_DIR = path.join("songs", "dist");

// Define interfaces for our JSON song structure
interface SongMetadata {
  Artist: string;
  AssetId: string;
  CoverImageAssetId: string;
  Description: string;
  Difficulty: number | { Rate: number; Overall: number }[];
  Filename: string; // Song title
  HitSFXGroup: number;
  MD5Hash: string;
  Mapper: string;
  NotePrebufferTime: number;
  TimeOffset: number;
  Volume: number;
}

interface HitObject {
  Time: number;
  Track: number;
  Duration?: number;
}

interface SongData {
  metadata: SongMetadata;
  objects: HitObject[];
}

function generateHitObjectData(hitObjects: HitObject[]): {
  npsGraph: number[];
  maxNPS: number;
  averageNPS: number;
  singles: number;
  holds: number;
} {
  let singles = 0;
  let holds = 0;

  if (hitObjects.length === 0) {
    return {
      npsGraph: [],
      maxNPS: 0,
      averageNPS: 0,
      singles: 0,
      holds: 0,
    };
  }

  const lastHitObject = hitObjects[hitObjects.length - 1];
  const length = lastHitObject.Time + (lastHitObject.Duration || 0);

  const npsGraph: number[] = [];
  const CHUNKS = 50;

  const chunkNotes: number[] = Array(CHUNKS).fill(0);
  const chunkDuration = length / CHUNKS;

  for (const hitObject of hitObjects) {
    if (hitObject.Duration !== undefined && hitObject.Duration > 0) {
      holds++;
    } else {
      singles++;
    }

    const time = hitObject.Time;
    let chunkIndex = Math.min(Math.ceil(time / chunkDuration), CHUNKS) - 1;
    if (chunkIndex < 0) chunkIndex = 0;

    chunkNotes[chunkIndex]++;
  }

  const chunkDurationSeconds = chunkDuration / 1000;
  for (let i = 0; i < CHUNKS; i++) {
    if (chunkDurationSeconds > 0) {
      npsGraph[i] = chunkNotes[i] / chunkDurationSeconds;
    } else {
      npsGraph[i] = 0;
    }
  }

  let maxNPS = 0;
  let averageNPS = 0;
  for (const count of npsGraph) {
    if (count > maxNPS) {
      maxNPS = count;
    }
    averageNPS += count;
  }
  averageNPS = npsGraph.length > 0 ? averageNPS / npsGraph.length : 0;

  return { npsGraph, maxNPS, averageNPS, singles, holds };
}

function toBase64(data: string): string {
  return Buffer.from(data, "binary").toString("base64");
}

async function main() {
  if (!fs.existsSync(SONGS_DB_DIR)) {
    console.error(`Songs DB directory not found: ${SONGS_DB_DIR}.`);
    process.exit(1);
  }

  // Clean and recreate dist directory
  if (fs.existsSync(DIST_DIR)) {
    fs.rmSync(DIST_DIR, { recursive: true, force: true });
  }
  fs.mkdirSync(DIST_DIR, { recursive: true });

  const entries = fs.readdirSync(SONGS_DB_DIR, { withFileTypes: true });

  let processedCount = 0;
  let skippedCount = 0;

  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.endsWith(".json")) continue;

    const songFilePath = path.join(SONGS_DB_DIR, entry.name);

    try {
      const songData: SongData = JSON.parse(
        fs.readFileSync(songFilePath, "utf8")
      );
      const { metadata, objects } = songData;

      let difficulty = 0;
      if (Array.isArray(metadata.Difficulty)) {
        const rateMetadata = metadata.Difficulty.find((d) => d.Rate === 100);
        difficulty = rateMetadata ? rateMetadata.Overall : 0;
      } else {
        difficulty = metadata.Difficulty;
      }

      const lastHitObject = objects[objects.length - 1];
      const length = lastHitObject
        ? lastHitObject.Time + (lastHitObject.Duration || 0)
        : 0;

      const { npsGraph, maxNPS, averageNPS, singles, holds } =
        generateHitObjectData(objects);

      // Calculate attributes with Rojo type wrappers
      const songAttributes: { [key: string]: any } = {
        ArtistName: { String: metadata.Artist || "Unknown" },
        SongName: { String: metadata.Filename || "Unknown" },
        CharterName: { String: metadata.Mapper || "Unknown" },
        Description: { String: metadata.Description || "" },
        AudioID: { String: metadata.AssetId || "rbxassetid://0" },
        CoverImageAssetId: {
          String: metadata.CoverImageAssetId || "rbxassetid://0",
        },
        Volume: {
          Float64:
            metadata.Volume !== undefined && metadata.Volume !== null
              ? Number(metadata.Volume)
              : 1,
        },
        HitSFXGroup: {
          Float64:
            metadata.HitSFXGroup !== undefined
              ? Number(metadata.HitSFXGroup)
              : 0,
        },
        TimeOffset: {
          Float64:
            metadata.TimeOffset !== undefined ? Number(metadata.TimeOffset) : 0,
        },
        Difficulty: { Float64: Number(difficulty || 0) },
        Length: { Float64: Number(length || 0) },
        ObjectCount: { Float64: Number(objects.length) },
        MD5Hash: { String: metadata.MD5Hash || "" },
        NPSGraph: { String: npsGraph.join(",") },
        MaxNPS: { Float64: Number(maxNPS) },
        AverageNPS: { Float64: Number(averageNPS) },
        TotalSingleNotes: { Float64: Number(singles) },
        TotalHoldNotes: { Float64: Number(holds) },
      };

      // Process Chart Data
      const encodedNotes = JSON.stringify(objects);
      const compressedNotes = pako.deflate(encodedNotes, { level: 9 });
      const chartStringValue = toBase64(
        Buffer.from(compressedNotes).toString("binary")
      );

      // Output Structure:
      // songs/dist/<MD5>/
      //   init.meta.json (Folder properties + attributes)
      //   ChartString.txt (The StringValue content)

      const folderName = metadata.MD5Hash || "unknown_" + Date.now();
      const songOutputDir = path.join(DIST_DIR, folderName);
      fs.mkdirSync(songOutputDir, { recursive: true });

      // 1. Write init.meta.json
      // Rojo 7+ expects 'Attributes' inside 'properties' to be a map of serialized attribute values.
      const metaJson = {
        className: "Folder",
        properties: {
          Name: metadata.Filename || "Unknown Song",
          Attributes: songAttributes,
        },
      };
      fs.writeFileSync(
        path.join(songOutputDir, "init.meta.json"),
        JSON.stringify(metaJson, null, 2)
      );

      // 2. Write ChartString.txt
      // This will be synced by Rojo as a StringValue named 'ChartString' child of the Folder.
      fs.writeFileSync(
        path.join(songOutputDir, "ChartString.txt"),
        chartStringValue
      );

      processedCount++;
      // console.log(`  -> Built ${folderName} (${metadata.Filename})`);
    } catch (err) {
      console.error(`Failed to build ${entry.name}:`, err);
      skippedCount++;
    }
  }

  console.log(`
Build complete! Processed ${processedCount} songs, skipped ${skippedCount}.`);
}

main().catch(console.error);
