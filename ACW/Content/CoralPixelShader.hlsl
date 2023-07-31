struct PixelInput
{
    float4 position : SV_POSITION;
};

float4 main(PixelInput input) : SV_Target
{
    // You can apply color changing and other effects here if needed
    return float4(0.2f, 0.7f, 0.4f, 1.0f); // Example: Coral green color
}
