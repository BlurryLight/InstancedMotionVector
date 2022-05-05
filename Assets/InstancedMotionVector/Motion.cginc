#include "Common.cginc"

float4x4 _NonJitteredVP;
float4x4 _PreviousVP;
float4x4 _PreviousM;

struct Attributes
{
    float4 position : POSITION;
    uint instanceID : SV_InstanceID;
};

struct Varyings
{
    float4 position : SV_POSITION;
    float4 transfer0 : TEXCOORD0;
    float4 transfer1 : TEXCOORD1;
};

Varyings Vertex(Attributes input)
{
    Transform anim0 = CalculateAnimation(input.instanceID, _CurrentTime - _DeltaTime);
    Transform anim1 = CalculateAnimation(input.instanceID, _CurrentTime);

    float4 vp0 = mul(anim0.instanceToObject, input.position);
    float4 vp1 = mul(anim1.instanceToObject, input.position); //计算由动画带来的顶点位置之差。vp0为上一阵动画的顶点位置,vp1是当前帧的

    Varyings o;
    o.position = UnityObjectToClipPos(vp1);
    o.transfer0 = mul(_PreviousVP, mul(_PreviousM, vp0)); //把vp0乘以上一阵的mvp
    o.transfer1 = mul(_NonJitteredVP, mul(unity_ObjectToWorld, vp1)); //vp1乘以这一帧的mvp
    return o;
}

float4 Fragment(Varyings input) : SV_Target
{
    float3 hp0 = input.transfer0.xyz / input.transfer0.w;
    float3 hp1 = input.transfer1.xyz / input.transfer1.w; // TEXTURE_COORD0不会自动做齐次除法，手动转到UV坐标下

    float2 vp0 = (hp0.xy + 1) / 2;
    float2 vp1 = (hp1.xy + 1) / 2;

#if UNITY_UV_STARTS_AT_TOP
    vp0.y = 1 - vp0.y;
    vp1.y = 1 - vp1.y;
#endif

    return half4(vp1 - vp0, 0, 1);
}
