# generate-wiki

Auto-generate [Docsify](https://docsify.js.org/) sidebar and landing page for wiki folders on a NAS.

## What it does

- Scans a root directory for folders containing `.md` files
- Generates `_sidebar.md` for each folder (Docsify navigation)
- Creates a `index.html` landing page listing all wiki projects
- Sets up Docsify boilerplate (`index.html`, `.nojekyll`) per folder

## Usage

```bash
bash generate-wiki.sh
```

By default the script looks for wiki folders in `/share/Web`. Override with:

```bash
WEB_ROOT=/path/to/your/docs bash generate-wiki.sh
```

## Folder structure

```
/share/Web/
├── generate-wiki.sh
├── index.html          # generated landing page
├── project-a/
│   ├── README.md
│   ├── _sidebar.md     # generated
│   ├── index.html      # generated (Docsify)
│   ├── setup.md
│   └── guides/
│       └── getting-started.md
└── project-b/
    └── ...
```

## Docsify config

The generated `index.html` uses these Docsify settings:

| Setting | Value | Note |
|---------|-------|------|
| `loadSidebar` | `true` | Uses `_sidebar.md` for navigation |
| `subMaxLevel` | `3` | Show up to H3 in sidebar |
| `relativePath` | `false` | Resolve paths from Docsify root (see gotcha below) |
| `search` | enabled | Full-text search across docs |
| `auto2top` | `true` | Scroll to top on page change |

### Gotcha: relativePath

`relativePath` **must be `false`**. When set to `true`, Docsify resolves sidebar links relative to the current page's route — causing path duplication when navigating across sections:

```
# Expected (relativePath: false)
http://host/wiki/#/guides/setup

# Bug (relativePath: true) — after clicking from another section
http://host/wiki/#/guides/guides/setup
```

If you have an existing wiki with `relativePath: true` in `index.html`, fix it:

```bash
sed -i 's/relativePath: true/relativePath: false/' /share/Web/*/index.html
```

Note: `setup_docsify()` only creates `index.html` if it doesn't exist. To regenerate with the fix, delete the old file first:

```bash
rm /share/Web/my-project/index.html
bash generate-wiki.sh
```

## File permissions

When deploying docs via `rsync` from macOS, files may arrive with restrictive permissions (`600`) that prevent the web server (nginx) from reading them. Fix with:

```bash
chmod -R a+rX /share/Web/my-project/
```

The `a+rX` flag adds read for all users and execute only on directories (uppercase X).

## Requirements

- Bash
- Standard Unix tools (`sed`, `awk`, `find`)
