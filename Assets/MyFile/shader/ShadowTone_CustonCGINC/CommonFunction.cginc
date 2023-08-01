fixed RGBA2BW(half4 RGBA)
{
    return dot(RGBA.rgb,fixed3(0.299, 0.587, 0.114));
}