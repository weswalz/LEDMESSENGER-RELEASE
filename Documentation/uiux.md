# 🎨 LEDMESSENGER – Interface Design Spec

This document outlines the intended look, structure, and interaction logic of the LEDMESSENGER UI based on the design in your screenshots. It breaks down the layout, visual style, component hierarchy, colors, fonts, spacing, and all functional behavior.

---

## 🧭 App Layout Overview

The LEDMESSENGER interface follows a **centered, full-width vertical stack layout** with high contrast styling and large touch-friendly elements — ideal for nightclub settings and low-light environments.

```plaintext
╭────────────────────────────────────────────────────────────────────╮
│                       LED WALL MESSENGER                           │
│  • PEER CONNECTED     • RESOLUME CONNECTED     [Setup] [Clear] [+]│
├────────────────────────────────────────────────────────────────────┤
│ INSTRUCTIONS: Queue message → Send to LED wall                    │
├────────────────────────────────────────────────────────────────────┤
│ Message Queue Section                                             │
│ ┌────────────────────────────┐ ┌────────┐ ┌─────┐ ┌─────────────┐ │
│ │ Table Number 5             │ │ DELETE │ │EDIT │ │SEND TO WALL │ │
│ │ HBD TO UR MAMA             │ └────────┘ └─────┘ └─────────────┘ │
│ └────────────────────────────┘                                     │
│ ┌────────────────────────────┐                                     │
│ │ Table Number 4             │               [CANCEL MESSAGE]     │
│ │ BIG TIDDIES                │                                     │
│ └────────────────────────────┘                                     │
├────────────────────────────────────────────────────────────────────┤
│ Modal: New Message                                                │
│ ┌───────────────────────────────┐                                  │
│ │  New Message                 │                                   │
│ │  [ Table Number     ][5    ] │                                   │
│ │  [ Message          ][HBD…] │                                   │
│ │  [ Cancel ]           [QUEUE MESSAGE]                           │
│ └───────────────────────────────┘                                  │
╰────────────────────────────────────────────────────────────────────╯
```

---

## 🧱 Visual Hierarchy & Typography

### ✅ Primary Colors

| Element                     | Color                     | Notes                            |
|----------------------------|---------------------------|----------------------------------|
| Background                 | `#000000` (pure black)    | Full app background              |
| Accent Purple              | `#B667F1` (approx)         | Buttons, highlights              |
| Button Hover Purple        | Slightly brighter purple  | For hover/focus states           |
| Connected Indicators       | Purple + Green            | Peer (purple), Resolume (green)  |
| Delete Buttons             | `#FF4D4D` (vivid red)      | DELETE action emphasis           |
| Text                       | White + light gray        | High contrast; uppercase headers |

### ✅ Fonts & Sizes

- **Header (App title):** All caps, bold, sans-serif (SF Pro / system default), approx 20–24pt.
- **Buttons:** All caps, bold, sans-serif, white text on gradient purple backgrounds.
- **Table Labels:** White, bold, 14–16pt, prefixed with “Table Number X”.
- **Message Body:** All caps (for most), regular weight, 13–15pt.
- **Queue Buttons:** DELETE in red, EDIT and SEND TO WALL in gradient purple.
- **Cancel Message Button:** Full-width, bold, upper-right aligned in its row.

---

## 🧭 Top Navigation Bar

### 🏷 App Header
- **Label:** `LED WALL MESSENGER`
- **Style:** Uppercase, bold, centered.
- **Color:** White or slightly off-white.

### 🔵 Connection Status Indicators
- Left-aligned under the header.
- **Peer Connected:** Purple dot + label.
- **Resolume Connected:** Green dot + label.
- Small size (10–12pt), all caps.

### 🟪 Action Buttons
- Positioned top-right.
- **Buttons:** `Setup`, `Clear Screen`, `New Message`
- Style:
  - Rounded pill shape.
  - Gradient fill: purple to darker purple.
  - White bold all-caps text.
  - Padding: 12–16px horizontal, 6–8px vertical.
  - Spacing: Even with ~8px gap between each.

---

## 📥 Message Queue Section

### 📦 Each Message Entry
- **Layout:** Card-like container with soft purple glow border.
- **Structure:**
  - **Top Line:** Table Number Label (e.g. “Table Number 5”) – bold.
  - **Body:** Message content – uppercase, centered or left-aligned.
- **Buttons:**
  - Inline below message (in first screenshot):
    - `DELETE` – red button.
    - `EDIT` – purple button.
    - `SEND TO WALL` – purple button.
  - **OR** full-width right-aligned `CANCEL MESSAGE` (second screenshot).
- **Padding:** ~16–24px vertical spacing between cards.
- **Borders:** Soft glowing outline (purplish), rounded corners (~12px radius).

---

## 🧾 Message Modal

### 🆕 New Message Dialog
- **Background:** Rounded rectangle with soft black/purple fill.
- **Title:** `New Message` – centered, bold.
- **Fields:**
  - `TABLE NUMBER` – label above input, input has default like “5”.
  - `MESSAGE` – label above input, input is single line or multi-line.
  - Fields styled with light border and filled with dark purple.
- **Buttons:**
  - **Left:** `Cancel` (gradient purple button).
  - **Right:** `Queue Message` (main action, gradient purple).
- **Layout:** Centered modal with slight drop shadow and rounded corners (~16px).

---

## ⚙️ Setup Screen

### 🛠 General Info
- Large title: `LED MESSENGER`
- Centered IP address box in purple box (`172.17.20.115` example).
- Instructions below:
  - "Make sure port 2269 is open in Resolume Preferences..."
  - **Font size:** Small (10–12pt), light gray/purple.

### 🎛 Layer & Slot Selectors
- **Stepper controls**: One each for Layer and Slot.
  - **Layer:** Default is 5
  - **Slot:** Default is 3
- Style: Bold label above, numeric stepper controls below.

### 🚀 Launch Button
- Label: `LET’S GO!`
- Full-width purple gradient button.
- Bold, all-caps text.
- Rounded, prominent at bottom of Setup screen.

---

## 🧠 Behavior Summary

| Interaction           | Behavior                                                                 |
|-----------------------|--------------------------------------------------------------------------|
| **“New Message”**     | Opens modal with fields for table number and message content.            |
| **“Queue Message”**   | Adds message to queue with selected prefix.                              |
| **“Send to Wall”**    | Sends text to Resolume’s configured clip via OSC.                        |
| **“Cancel Message”**  | Clears text on wall and removes message from queue.                      |
| **“Delete”**          | Removes message from queue without sending.                              |
| **“Clear Screen”**    | Immediately sends OSC to blank clip and clears all messages.             |
| **“Setup”**           | Opens configuration screen for Layer/Slot and IP overview.               |

---

## 🧾 UX Philosophy

- ✅ **Big targets, bold text** – everything designed for nightclub conditions (dark + fast).
- ✅ **Idiot-proof flow** – linear queue with obvious actions: Queue → Send → Clear.
- ✅ **Immediate feedback** – text shows or clears with no delay, status updates live.
- ✅ **Strict message control** – only one visible at a time; no automation to confuse staff.
- ✅ **Visually intuitive** – bright purple for go, red for delete, distinct sections.

---

## 🎯 Target Look Goal

You're aiming to **rebuild this exact layout and visual polish**, ensuring the current app matches this design language and functional minimalism. It’s fast, elegant, non-cluttered, and immediately usable without training.

Let me know if you'd like a Figma mockup or screenshot-ready component guide for implementation.

