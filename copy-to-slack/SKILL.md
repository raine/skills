---
name: copy-to-slack
description: Convert markdown to Slack-ready rich text and copy to clipboard.
allowed-tools: Bash, Read
---

Convert a markdown file to rich text and copy it to the clipboard so it can be
pasted into Slack with formatting intact.

## Input

The user provides either:

- A file path as `$ARGUMENTS`
- A file path from recent conversation context

## Steps

1. Read the markdown file
2. Manually convert the markdown to HTML (do NOT use pandoc or any external
   tool). Apply these conversions:
   - `**bold**` → `<strong>bold</strong>`
   - `_italic_` / `*italic*` → `<em>italic</em>`
   - `` `code` `` → `<code>code</code>`
   - Fenced code blocks → `<pre><code>...</code></pre>`
   - `- item` / `* item` → `<ul><li>item</li></ul>`
   - `1. item` → `<ol><li>item</li></ol>`
   - `[text](url)` → `<a href="url">text</a>`
   - `# Header` → `<strong>Header</strong>` (Slack has no native headers)
   - Paragraph breaks → `<br><br>` (Slack ignores `<p>` margins, so use
     `<br><br>` between paragraphs for visible spacing)
3. Also prepare a plain-text version (strip markdown syntax)
4. Copy to clipboard with both HTML and plain-text representations. Use `>|`
   instead of `>` for redirects (zsh has noclobber set). Use this snippet:

```bash
html_file=$(mktemp)
plain_file=$(mktemp)

printf '%s' "$html" >| "$html_file"
printf '%s' "$plain" >| "$plain_file"

swift -e "
import AppKit
let html = try! String(contentsOfFile: \"$html_file\", encoding: .utf8)
let plain = try! String(contentsOfFile: \"$plain_file\", encoding: .utf8)
let pb = NSPasteboard.general
pb.clearContents()
pb.setString(html, forType: .html)
pb.setString(plain, forType: .string)
"

rm -f "$html_file" "$plain_file"
```

5. Confirm to the user what was copied

## Markdown → Slack formatting mapping

Slack's rich text paste interprets HTML. Key mappings:

- `**bold**` → `<strong>` → bold in Slack
- `_italic_` → `<em>` → italic in Slack
- `` `code` `` → `<code>` → inline code in Slack
- Code blocks → `<pre><code>` → code blocks in Slack
- `- item` → `<ul><li>` → bullet lists in Slack
- `[text](url)` → `<a href>` → clickable links in Slack
- Headers → bold text (Slack doesn't have native headers)
