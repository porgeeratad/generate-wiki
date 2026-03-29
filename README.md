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

## Requirements

- Bash
- Standard Unix tools (`sed`, `awk`, `find`)
