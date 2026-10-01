# JavaScript Installation Notes

This project now uses npm + esbuild for the module-based JavaScript bundles, including EDTF.

## Install

Run:

```bash
npm install
```

This installs the JavaScript dependencies declared in `package.json`, including:

- `@tiptap/core`
- `@tiptap/extension-mention`
- `@tiptap/pm`
- `@tiptap/starter-kit`
- `edtf`
- `esbuild`

## Build

Run:

```bash
npm run build
```

This builds the module entry points in `app/javascript/` into bundled files under `app/assets/builds/`.

For local development, use:

```bash
npm run build:watch
```

## What EDTF Uses

The EDTF field is now loaded from:

- `app/javascript/edtf_subfield.js`

The built asset is:

- `app/assets/builds/edtf_subfield.js`

That module intentionally keeps `window.edtf` and `window.edtf_format` available for legacy code paths, including `app/assets/javascripts/marc_editor_validation.js`, which still calls `edtf(...)` directly.

## Where It Is Injected

The ActiveAdmin head patch that injects the JavaScript bundle is:

- `lib/patches/active_admin/importmaps.rb`

That file now adds the built EDTF bundle and the Tiptap mention bundle to ActiveAdmin pages.

For non-ActiveAdmin pages, the EDTF bundle is also included from:

- `app/views/layouts/application.html.erb`

## Old Path Replaced

The old EDTF importmap/CDN path is no longer used.

The retired file was:

- `app/javascript/active_admin_importmaps.js`


# How to break the proxy

On the local machine

```
brew install privoxy
brew services start privoxy
```

Then connect to the remote machine

```
ssh -R 8118:localhost:8118 muscat-test
```

and on the remote machine the http proxy is on 8118

```
HTTP_PROXY=http://localhost:8118 HTTPS_PROXY=http://localhost:8118 npm install
```