#!/bin/bash

# Define input and output directories
input_folder="./images"
output_folder="./images/output"

# Check if required tools are installed
if ! command -v magick &> /dev/null || ! command -v potrace &> /dev/null; then
    echo "Error: ImageMagick or potrace is not installed."
    echo "Please install with: sudo apt-get install imagemagick potrace"
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
    
    # Step 1: Convert PNG to BMP with transparency handling
    magick "$file" -background white -alpha remove -alpha off "$temp_bmp"
    
    # Step 2: Trace BMP to SVG with potrace
    potrace "$temp_bmp" \
            --svg \
            --output "$temp_svg" \
            --turdsize 2 \
            --alphamax 1 \
            --color '#000000' \
            --opttolerance 0.2
    
    # Step 3: Convert SVG to PDF using Inkscape
    inkscape "$temp_svg" \
             --export-type=pdf \
             --export-filename="$output_file"
    
    # Clean up temporary files
    rm "$temp_bmp" "$temp_svg"
    
    if [ -s "$output_file" ]; then
        echo "Successfully converted: $output_file"
    else
        echo "Error converting: $file"
    fi
done

echo "Conversion complete!"