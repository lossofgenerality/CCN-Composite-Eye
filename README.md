# CCN Composite Eye

A camera page that turns a photo into text. Point it at a page, sign, note, barcode or equation and press **Take photo**. For each photo it adds:

- **CODES** – barcodes and QR codes, read in the browser
- **TEXT** – every piece of text in the photo, as written
- **DESCRIPTION** – what the photo shows, in 2–5 sentences
- **WOLFRAM** – any maths in the photo, written as Wolfram Language code

Photos are read by Claude through **CCN Cloud** (`CameraKernel` on Wolfram Cloud), so no Claude API key is kept in the page.

## Use

1. Open `index.html` in a browser (Chrome, Edge, Safari or Firefox) and allow the camera.
2. Type your **WOLFRAM_KEY** into the field at the top. The label beside it should change to *Connected · Wolfram 15*.
3. Zoom with the slider, the − / + buttons, pinch (touch screens) or Ctrl/⌘ + scroll.
4. Press **Take photo**. Results are added to the box; **Copy** and **Clear** work on all of it.

The key is remembered in that browser only. Clearing the field forgets it.

## Settings

The CCN Cloud settings are the first block in `<head>`:

```html
<script>
window.LAPLACIAN_LAB_CONFIG = window.LAPLACIAN_LAB_CONFIG || {
  MODEL: "claude-sonnet-5-5",
  WOLFRAM_URL: "https://www.wolframcloud.com/obj/ccn2/CameraKernel"
};
</script>
```

## Kernel

`kernel/CameraKernel.wl` deploys the backend from a signed-in Mathematica or Wolfram Cloud notebook:

1. `CloudPut` the Claude API key into a private Cloud object (once).
2. Set `secret` to the WOLFRAM_KEY people will type into the page, then run the `CloudDeploy`.

The kernel has two modes: `wolfram` evaluates code (`code_b64`, UTF-8 base64) and `chat` forwards a Claude Messages request (`payload_b64`). Requests without the right `key` are refused.

---

© Computational Classnotes · CC BY-NC-SA 4.0
