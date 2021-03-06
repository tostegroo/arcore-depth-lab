//-----------------------------------------------------------------------
// <copyright file="AndyParticle.shader" company="Google LLC">
//
// Copyright 2020 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// </copyright>
//-----------------------------------------------------------------------

Shader "ARRealism/AndyParticle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Space]
        // The size of screen-space alpha blending between visible and occluded regions.
        _OcclusionBlendingScale ("Occlusion blending scale", Range(0, 1)) = 0.01
        // The bias added to the estimated depth. Useful to avoid occlusion of objects anchored to planes.
        _OcclusionOffsetMeters ("Occlusion offset [meters]", Float) = 0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }
        LOD 100

        ZWrite Off
        Blend OneMinusDstColor One // Soft Additive

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Assets/GoogleARCore/SDK/Materials/ARCoreDepth.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float2 uvDepth : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float4 screenPos = ComputeScreenPos(o.vertex);
                float2 screenUV = screenPos.xy / screenPos.w;
                o.uvDepth = ArCoreDepth_GetUv(screenUV);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Screen pixel coordinate, to lookup depth texture value.
                float occlusionBlending =
                    ArCoreDepth_GetVisibility(i.uvDepth, UnityWorldToViewPos(i.worldPos));

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                col.rgb *= col.a * occlusionBlending;
                return col;
            }
            ENDCG
        }
    }
}
