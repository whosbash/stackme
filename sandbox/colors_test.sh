#!/bin/bash

# Foreground colors
echo "== Foreground Colors =="
for i in {30..37}; do
    echo -e "\033[${i}mColor ${i}\033[0m"
done

# Bold Foreground colors
echo -e "\n== Bold Foreground Colors =="
for i in {30..37}; do
    echo -e "\033[1;${i}mBold Color ${i}\033[0m"
done

# Background colors
echo -e "\n== Background Colors =="
for i in {40..47}; do
    echo -e "\033[${i}m\033[30mBackground Color ${i}\033[0m"
done

# Combined foreground and background colors
echo -e "\n== Combined Foreground and Background Colors =="
for fg in {30..37}; do
    for bg in {40..47}; do
        echo -ne "\033[${fg};${bg}mFG ${fg} BG ${bg}\033[0m  "
    done
    echo ""
done

# Text styles
echo -e "\n== Text Styles =="
echo -e "\033[1mBold\033[0m"
echo -e "\033[2mDim\033[0m"
echo -e "\033[4mUnderline\033[0m"
echo -e "\033[7mReverse\033[0m"
echo -e "\033[5mBlink\033[0m"
echo -e "\033[8mInvisible\033[0m"
echo -e "\033[9mStrikethrough\033[0m"
echo -e "\033[0mNormal"

echo -e "\n== Reset All Styles =="
echo -e "\033[0mThis is reset to normal"
