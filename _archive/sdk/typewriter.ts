export class Typewriter {
  private buf: string[] = [];
  private lvl = 0;

  line(s = "") {
    this.buf.push("  ".repeat(this.lvl) + s);
  }

  raw(s = "") {
    this.buf.push(s);
  }

  blank() {
    this.buf.push("");
  }

  indent<T>(fn: () => T): T {
    this.lvl++;
    const r = fn();
    this.lvl--;
    return r;
  }

  block(head: string, body: () => void, tail?: string) {
    this.line(head);
    this.indent(body);
    if (tail) this.line(tail);
  }

  var(name: string, value: any) {
    this.line(`local ${name} = ${value}`);
  }

  join(items: string[], sep: string) {
    return items.join(sep);
  }

  toString() {
    return this.buf.join("\n");
  }
}
