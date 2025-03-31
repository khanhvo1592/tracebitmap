#!/bin/bash

# Define input and output directories
input_folder="./images"
output_folder="./images/output"

# Check if required tools are installed
if ! command -v magick &> /dev/null || ! command -v potrace &> /dev/null || ! command -v inkscape &> /dev/null; then
    echo "Error: ImageMagick, potrace, or Inkscape is not installed."
    echo "Please install with: sudo apt-get install imagemagick potrace inkscape"
    exit 1
fi

# Create output folder if it doesn't exist
mkdir -p "$output_folder"

# Process each PNG file
for file in "$input_folder"/*.png; do
    filename=$(basename "$file" .png)
    temp_bmp="$output_folder/${filename}_temp.bmp"
    temp_svg="$output_folder/${filename}_temp.svg"
    output_file="$output_folder/${filename}.pdf"
    
    echo "Converting: $filename.png"
    
    # Step 1: Convert PNG to BMP with transparency handling and set resolution
    magick "$file" -density 72 -units PixelsPerInch -background white -alpha remove -alpha off "$temp_bmp"
    
    # Step 2: Trace BMP to SVG with potrace
    potrace "$temp_bmp" \
            --svg \
            --output "$temp_svg" \
            --turdsize 2 \
            --alphamax 1 \
            --color '#000000' \
            --opttolerance 0.2
    
    # Step 3: Get original PNG dimensions
    dimensions=$(magick identify -format "%wx%h" "$file")
    width=$(echo $dimensions | cut -d'x' -f1)
    height=$(echo $dimensions | cut -d'x' -f2)

    # Step 4: Convert SVG to PDF using Inkscape with specified dimensions and DPI
    inkscape "$temp_svg" \
             --export-type=pdf \
             --export-filename="$output_file" \
             --export-width="$width" \
             --export-height="$height" \
             --export-dpi=72
    
    # Clean up temporary files
    rm "$temp_bmp" "$temp_svg"
    
    if [ -s "$output_file" ]; then
        echo "Successfully converted: $output_file"
    else
        echo "Error converting: $file"
    fi
done

echo "Conversion complete!"