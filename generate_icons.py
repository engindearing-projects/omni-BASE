#!/usr/bin/env python3
"""
Generate OmniTAK app icons with greenish background and white text
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Tactical green color scheme
BACKGROUND_COLOR = "#2D5F3F"  # Military/tactical green
TEXT_COLOR = "#FFFFFF"  # White
ACCENT_COLOR = "#5C9A6B"  # Lighter green for subtle details

# Icon sizes needed for iOS
ICON_SIZES = [20, 29, 40, 58, 60, 80, 87, 120, 152, 167, 180, 1024]

def create_icon(size):
    """Create a single icon at the specified size"""
    # Create image with green background
    img = Image.new('RGB', (size, size), BACKGROUND_COLOR)
    draw = ImageDraw.Draw(img)

    # Add subtle gradient effect with a lighter green circle
    center = size // 2
    radius = int(size * 0.45)
    draw.ellipse(
        [(center - radius, center - radius), (center + radius, center + radius)],
        fill=ACCENT_COLOR,
        outline=None
    )

    # Calculate font size based on icon size
    # For larger icons, use "OmniTAK", for smaller ones use "OT"
    if size >= 152:
        text = "OmniTAK"
        font_size = max(12, int(size * 0.12))
    elif size >= 80:
        text = "Omni\nTAK"
        font_size = max(11, int(size * 0.14))
    else:
        text = "OT"
        font_size = max(8, int(size * 0.35))

    # Try to use a system font, fall back to default if not available
    font = None
    font_paths = [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]

    for font_path in font_paths:
        try:
            font = ImageFont.truetype(font_path, font_size)
            break
        except Exception as e:
            continue

    # If no font found, skip text rendering for this icon
    if font is None:
        print(f"    Warning: Could not load font for size {size}, using plain background")
        return img

    # Get text bounding box for centering
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]

    # Draw text with slight shadow for depth
    shadow_offset = max(1, size // 100)
    if shadow_offset > 0:
        draw.text((x + shadow_offset, y + shadow_offset), text,
                 fill="#1A3A28", font=font, align="center")

    # Draw main text
    draw.text((x, y), text, fill=TEXT_COLOR, font=font, align="center")

    return img

def main():
    output_dir = "apps/omnitak_ios_test/OmniTAKTest/Assets.xcassets/AppIcon.appiconset"

    print("Generating OmniTAK app icons...")

    for size in ICON_SIZES:
        print(f"  Creating {size}x{size} icon...")
        icon = create_icon(size)
        output_path = os.path.join(output_dir, f"{size}.png")
        icon.save(output_path, "PNG")

    print(f"\n✅ Successfully generated {len(ICON_SIZES)} app icons!")
    print(f"📁 Location: {output_dir}")
    print("\nNext steps:")
    print("1. Open Xcode")
    print("2. The new icons should appear automatically in Assets.xcassets")
    print("3. Build and run to see the new OmniTAK icon!")

if __name__ == "__main__":
    main()
