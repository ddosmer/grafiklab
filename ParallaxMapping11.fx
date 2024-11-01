Texture2D ColorMap : register(t0);
Texture2D NormalHeightMap : register(t1);

SamplerState samLinear : register(s0);

cbuffer ConstantBuffer : register(b0)
{
    matrix World;
    matrix WorldViewProjection;
    float4 LightPosition;
    float4 EyePosition;
    float fHeightMapScale;
    int nMaxSamples;
    int key;
};

float nMinSamples = 4;

struct vertex
{
    float3 position : POSITION;
    float2 texcoord : TEXCOORD0;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 binormal : BINORMAL;
};

struct fragment
{
    float4 position : SV_Position;
    float2 texcoord : TEXCOORD0;
    float3 eye : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float3 light : TEXCOORD3;
};

struct pixel
{
    float4 color : SV_Target0;
};

fragment VS(vertex IN)
{
    fragment OUT;

	
    float3 P = mul(float4(IN.position, 1), World).xyz;
    float3 N = IN.normal;
    float3 E = P - EyePosition.xyz;
    float3 L = LightPosition.xyz - P;

	
    float3x3 tangentToWorldSpace;

    tangentToWorldSpace[0] = mul(normalize(IN.tangent), World);
    tangentToWorldSpace[1] = mul(normalize(IN.binormal), World);
    tangentToWorldSpace[2] = mul(normalize(IN.normal), World);
	
    float3x3 worldToTangentSpace = transpose(tangentToWorldSpace);

	
    OUT.position = mul(float4(IN.position, 1), WorldViewProjection);
    OUT.texcoord = IN.texcoord;

    OUT.eye = mul(E, worldToTangentSpace);
    OUT.normal = mul(N, worldToTangentSpace);
    OUT.light = mul(L, worldToTangentSpace);

    return OUT;
}



pixel PS(fragment IN)
{
    pixel OUT;

	
    float fParallaxLimit = -length(IN.eye.xy) / IN.eye.z;

	
    fParallaxLimit *= fHeightMapScale;
	
    if (key == 0 || key == 2)
    {
        fParallaxLimit = 0;
    }
	
    float2 vOffsetDir = normalize(IN.eye.xy);
    float2 vMaxOffset = vOffsetDir * fParallaxLimit;
	
    float3 N = normalize(IN.normal);
    float3 E = normalize(IN.eye);
    float3 L = normalize(IN.light);

	
    int nNumSamples = (int) lerp(nMaxSamples, nMinSamples, dot(E, N));
	
	
    float fStepSize = 1.0 / (float) nNumSamples;

	
    float2 dx = ddx(IN.texcoord);
    float2 dy = ddy(IN.texcoord);

    float fCurrRayHeight = 1.0;
    float2 vCurrOffset = float2(0, 0);
    float2 vLastOffset = float2(0, 0);
	
    float fLastSampledHeight = 1;
    float fCurrSampledHeight = 1;

    int nCurrSample = 0;

    while (nCurrSample < nNumSamples)
    {
		
        fCurrSampledHeight = NormalHeightMap.SampleGrad(samLinear, IN.texcoord + vCurrOffset, dx, dy).a;

        if (fCurrSampledHeight > fCurrRayHeight)
        {
			
            float delta1 = fCurrSampledHeight - fCurrRayHeight;
            float delta2 = (fCurrRayHeight + fStepSize) - fLastSampledHeight;
            float ratio = delta1 / (delta1 + delta2);

			
            vCurrOffset = (ratio) * vLastOffset + (1.0 - ratio) * vCurrOffset;
			
			
            nCurrSample = nNumSamples + 1;
        }
        else
        {
		
            nCurrSample++;

			
            fCurrRayHeight -= fStepSize;
			
		
            vLastOffset = vCurrOffset;
            vCurrOffset += fStepSize * vMaxOffset;

		
            fLastSampledHeight = fCurrSampledHeight;
        }
    }
	
	}
	
	
    float2 vFinalCoords = IN.texcoord + vCurrOffset;

	
    float4 vFinalColor = ColorMap.SampleGrad(samLinear, vFinalCoords, dx, dy);
	
    float3 vFinalNormal = NormalHeightMap.SampleGrad(samLinear, vFinalCoords, dx, dy); 

    if (key == 0 || key == 1)
    {
        vFinalNormal = N;
    }
    else
    {
        vFinalNormal = vFinalNormal * 2.0f - 1.0f;
    }
	
	

    float3 vAmbient = vFinalColor.rgb * 0.2f;
    float3 vDiffuse = vFinalColor.rgb * max(0.0f, dot(L, vFinalNormal.xyz)) * 0.8f;
	
    float3 reflection = reflect(-L, vFinalNormal);
    float3 viewDirection = normalize(-E);
    float specularAngle = max(0.0f, dot(reflection, viewDirection));
    float3 vSpecular = vFinalColor.rgb * pow(specularAngle, 64.0f);
    vFinalColor.rgb = vAmbient + vDiffuse + vSpecular;

    OUT.color = float4(vFinalColor.rgb, 1.0f);
	
	/*
	//Deney Sorulari

		float3 reflection = reflect(-L, N);
		float3 viewDirection = normalize(-E);
		float specularAngle = max(0.0f, dot(reflection, viewDirection));
		float3 vSpecular = vFinalColor.rgb * pow(specularAngle, 64.0f);
		vFinalColor.rgb = vAmbient + vDiffuse + vSpecular;
		OUT.color = float4(vFinalColor.rgb, 1.0f);

	*/
	
#ifdef GRIDLINES
	float2 vGridCoords = frac( vFinalCoords * 10.0f );
	if ( ( vGridCoords.x < 0.025f ) || ( vGridCoords.x > 0.975f ) )
		OUT.color = float4( 1.0f, 0.0f, 0.0f, 1.0f );
	if ( ( vGridCoords.y < 0.025f ) || ( vGridCoords.y > 0.975f ) )
		OUT.color = float4( 0.0f, 0.0f, 1.0f, 1.0f );
#endif

    return OUT;
}