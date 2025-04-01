brew install potrace imagemagick
Set excute script on Macos
chmod +x tracebitmap.sh  


# Run 
```bash
./tracebitmap.sh
```



# Windows Version
Để script có thể chạy trên Windows, chúng ta cần điều chỉnh một số điểm để tương thích. Đây là phiên bản cho cả Windows và macOS:

```bash:tracebitmap.sh
#!/bin/bash

# Function to check OS type
get_os_type() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        MINGW*|MSYS*|CYGWIN*) echo "windows";;
        *)         echo "unknown";;
    esac
}

# Set paths based on OS
OS_TYPE=$(get_os_type)
if [ "$OS_TYPE" = "windows" ]; then
    # Windows paths (assuming default installation locations)
    INKSCAPE_PATH="/c/Program Files/Inkscape/bin/inkscape.exe"
    MAGICK_PATH="/c/Program Files/ImageMagick-7.X/magick.exe"
    POTRACE_PATH="/c/Program Files/potrace/potrace.exe"
else
    # macOS paths
    INKSCAPE_PATH="inkscape"
    MAGICK_PATH="magick"
    POTRACE_PATH="potrace"
fi

# Define input and output directories
input_folder="./images"
output_folder="./images/output"

# Set fixed resolution
FIXED_DPI=300

# Check if required tools are installed
check_windows_tools() {
    if [ ! -f "$INKSCAPE_PATH" ]; then
        echo "Error: Inkscape not found. Please install from https://inkscape.org/"
        exit 1
    fi
    if [ ! -f "$MAGICK_PATH" ]; then
        echo "Error: ImageMagick not found. Please install from https://imagemagick.org/"
        exit 1
    fi
    if [ ! -f "$POTRACE_PATH" ]; then
        echo "Error: Potrace not found. Please install from http://potrace.sourceforge.net/"
        exit 1
    fi
}

check_mac_tools() {
    if ! command -v magick &> /dev/null || ! command -v potrace &> /dev/null || ! command -v inkscape &> /dev/null; then
        echo "Error: Required tools not found. Please install:"
        echo "brew install imagemagick potrace inkscape"
        exit 1
    fi
}

# Check tools based on OS
if [ "$OS_TYPE" = "windows" ]; then
    check_windows_tools
else
    check_mac_tools
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
    
    # Use appropriate command based on OS
    if [ "$OS_TYPE" = "windows" ]; then
        # Windows commands
        "$MAGICK_PATH" "$file" -units PixelsPerInch -density $FIXED_DPI -resample $FIXED_DPI "$temp_png"
        dimensions=$("$MAGICK_PATH" identify -format "%w %h" "$temp_png")
    else
        # macOS commands
        magick "$file" -units PixelsPerInch -density $FIXED_DPI -resample $FIXED_DPI "$temp_png"
        dimensions=$(magick identify -format "%w %h" "$temp_png")
    fi
    
    width_px=$(echo $dimensions | cut -d' ' -f1)
    height_px=$(echo $dimensions | cut -d' ' -f2)
    
    # Calculate inches and points
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
    
    # Convert PNG to BMP
    if [ "$OS_TYPE" = "windows" ]; then
        "$MAGICK_PATH" "$temp_png" -background white -alpha remove -alpha off "$temp_bmp"
    else
        magick "$temp_png" -background white -alpha remove -alpha off "$temp_bmp"
    fi
    
    # Trace BMP to SVG
    if [ "$OS_TYPE" = "windows" ]; then
        "$POTRACE_PATH" --svg --output "$temp_svg" --turdsize 2 --alphamax 1 --color '#000000' --opttolerance 0.2 "$temp_bmp"
    else
        potrace --svg --output "$temp_svg" --turdsize 2 --alphamax 1 --color '#000000' --opttolerance 0.2 "$temp_bmp"
    fi

    # Get viewBox and create final SVG
    viewbox=$(grep -o 'viewBox="[^"]*"' "$temp_svg" | head -1 | cut -d'"' -f2)
    
    # Create SVG with correct dimensions
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<svg
   width=\"${width_pt}pt\"
   height=\"${height_pt}pt\"
   viewBox=\"${viewbox}\"
   version=\"1.1\"
   xmlns=\"http://www.w3.org/2000/svg\">" > "$final_svg"

    sed -n '/<g/,/<\/g>/p' "$temp_svg" >> "$final_svg"
    echo "</svg>" >> "$final_svg"
    
    # Convert to PDF
    if [ "$OS_TYPE" = "windows" ]; then
        "$INKSCAPE_PATH" "$final_svg" --export-type=pdf --export-filename="$output_file" \
                        --export-area-page --export-width="${width_px}" \
                        --export-height="${height_px}" --export-dpi=$FIXED_DPI
    else
        inkscape "$final_svg" --export-type=pdf --export-filename="$output_file" \
                 --export-area-page --export-width="${width_px}" \
                 --export-height="${height_px}" --export-dpi=$FIXED_DPI
    fi
    
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
```

Để sử dụng trên Windows:

1. Cài đặt các công cụ cần thiết:
   - ImageMagick: https://imagemagick.org/script/download.php
   - Inkscape: https://inkscape.org/release/
   - Potrace: http://potrace.sourceforge.net/#downloading
   - Git Bash hoặc WSL để chạy script bash

2. Điều chỉnh đường dẫn trong script:
   - Kiểm tra và cập nhật `INKSCAPE_PATH`
   - Kiểm tra và cập nhật `MAGICK_PATH`
   - Kiểm tra và cập nhật `POTRACE_PATH`

3. Chạy script:
```bash
chmod +x tracebitmap.sh
./tracebitmap.sh
```

Thay đổi chính:
1. Thêm kiểm tra hệ điều hành
2. Hỗ trợ đường dẫn Windows
3. Xử lý các lệnh khác nhau cho Windows và macOS
4. Thêm hướng dẫn cài đặt cho Windows
