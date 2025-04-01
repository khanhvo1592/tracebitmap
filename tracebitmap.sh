#!/bin/bash

# Define input and output directories
input_folder="./images"
output_folder="./images/output"

# Set fixed resolution
FIXED_DPI=300

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
    temp_png="$output_folder/${filename}_300dpi.png"
    temp_bmp="$output_folder/${filename}_temp.bmp"
    temp_svg="$output_folder/${filename}_temp.svg"
    final_svg="$output_folder/${filename}_final.svg"
    output_file="$output_folder/${filename}.pdf"
    
    echo "Converting: $filename.png"
    
    # Step 0: Convert input PNG to 300 DPI
    magick "$file" \
           -units PixelsPerInch \
           -density $FIXED_DPI \
           -resample $FIXED_DPI \
           "$temp_png"
    
    # Get dimensions of the 300 DPI image
    dimensions=$(magick identify -format "%w %h" "$temp_png")
    width_px=$(echo $dimensions | cut -d' ' -f1)
    height_px=$(echo $dimensions | cut -d' ' -f2)
    
    # Calculate inches and points (round to integers for Inkscape)
    width_inches=$(echo "scale=2; $width_px / $FIXED_DPI" | bc)
    height_inches=$(echo "scale=2; $height_px / $FIXED_DPI" | bc)
    width_pt=$(echo "scale=0; $width_inches * 72 / 1" | bc)
    height_pt=$(echo "scale=0; $height_inches * 72 / 1" | bc)
    
    echo "Image info:"
    echo "Original file: $file"
    echo "300 DPI version: $temp_png"
    echo "Pixels: ${width_px}x${height_px}"
    echo "Inches: ${width_inches}x${height_inches}"
    echo "Points: ${width_pt}x${height_pt}"
    
    # Step 1: Convert 300 DPI PNG to BMP
    magick "$temp_png" -background white -alpha remove -alpha off "$temp_bmp"
    
    # Step 2: Trace BMP to SVG
    potrace "$temp_bmp" \
            --svg \
            --output "$temp_svg" \
            --turdsize 2 \
            --alphamax 1 \
            --color '#000000' \
            --opttolerance 0.2

    # Get viewBox from original SVG
    viewbox=$(grep -o 'viewBox="[^"]*"' "$temp_svg" | head -1 | cut -d'"' -f2)
    
    # Step 3: Create new SVG with correct dimensions and viewBox
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg
   width=\"${width_pt}pt\"
   height=\"${height_pt}pt\"
   viewBox=\"${viewbox}\"
   version=\"1.1\"
   xmlns=\"http://www.w3.org/2000/svg\">" > "$final_svg"

    # Extract path data and preserve transform from temp_svg
    sed -n '/<g/,/<\/g>/p' "$temp_svg" >> "$final_svg"
    
    echo "</svg>" >> "$final_svg"
    
    # Step 4: Convert to PDF
    inkscape "$final_svg" \
             --export-type=pdf \
             --export-filename="$output_file" \
             --export-area-page \
             --export-width="${width_px}" \
             --export-height="${height_px}" \
             --export-dpi=$FIXED_DPI
    
    # Clean up temporary files
    rm "$temp_png" "$temp_bmp" "$temp_svg" "$final_svg"
    
    if [ -s "$output_file" ]; then
        echo "Successfully converted: $output_file"
        echo "PDF dimensions: ${width_inches}x${height_inches} inches"
    else
        echo "Error converting: $file"
    fi
done

echo "Conversion complete!"