Shader "Custom/Puzzle Piece1" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_BorderColor("Border Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Mask("Mask (A)", 2D) = "white" {}
		_Mask2("Mask (A)", 2D) = "white" {}
		_Mask3("Mask (A)", 2D) = "white" {}
	    _Hue("Hue", Range(-0.5,0.5)) = 0.0
		_Saturation("Saturation", Range(0,2)) = 1.0	
		_Brightness("Brightness", Range(0,2)) = 1.0	
	    
	}

	SubShader{
		Tags{ "RenderType" = "Transparent" }
		LOD 200

		CGPROGRAM
        #pragma surface surf NoLighting alpha
//#pragma target 3.0
		sampler2D _MainTex;
		sampler2D _Mask;
		sampler2D _Mask2;
		sampler2D _Mask3;

		struct Input {
			float2 uv_MainTex;
			float2 uv2_Mask;
			float4 color : COLOR;
		};
		
		fixed4 LightingNoLighting(SurfaceOutput s, fixed3 lightDir, fixed atten)
         {
             fixed4 c;
             c.rgb = s.Albedo; 
             c.a = s.Alpha;
             return c;
         }

		float GetPieceAlpha(float pieceIdentifier, float pieceAlpha, float2 direction)
		{
		    if(pieceIdentifier == 0)
		    {
		        pieceAlpha *= tex2D(_Mask, direction);
		    }
            else if(pieceIdentifier == 1)
		    {
		        pieceAlpha *= tex2D(_Mask2, direction);
		    }
		    else if(pieceIdentifier == 2)
	        {
		        pieceAlpha *= tex2D(_Mask3, direction);
		    }

//            float zeroResult = step(0,pieceIdentifier);
//            float oneResult = step(1,pieceIdentifier);
//            float twoResult = step(2,pieceIdentifier);
//
//           pieceAlpha *= twoResult * tex2D(_Mask3, direction) + (1 - twoResult)*(oneResult * tex2D(_Mask2, direction) + (1 - oneResult)*(zeroResult * tex2D(_Mask,direction)));
//			 
			return pieceAlpha;
		}
		
		uniform float _Hue;
        uniform float _Saturation;
        uniform float _Brightness;
        
        float3 rgb2hsv(float3 c)
        {
          float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
          float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
          float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
        
          float d = q.x - min(q.w, q.y);
          float e = 1.0e-10;
          return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }
        
        float3 hsv2rgb(float3 c) 
        {
          c = float3(c.x, clamp(c.yz, 0.0, 1.0));
          float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
          float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
          return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }
        
        inline fixed4 adjustColor(fixed4 color)
        {
            float3 hsv = rgb2hsv(color.rgb);
            
            hsv.x += _Hue; 
            hsv.y *= _Saturation; 
            hsv.z *= _Brightness;
            
            color.rgb = hsv2rgb(hsv);
            
            return color;
        }

		fixed4 _Color;
		fixed4 _BorderColor;
		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
//			o.Albedo = c.rgb;
			o.Alpha = c.a;

			float2x2 rotationMatrix = float2x2(0, -1, 1, 0);	
			float2 uv_Top = float2(IN.uv2_Mask.x * 8, IN.uv2_Mask.y * 8);
			float2 uv_Left = mul(uv_Top.xy, rotationMatrix);
			float2 uv_Bot = mul(uv_Left.xy, rotationMatrix);
			float2 uv_Right = mul(uv_Bot.xy, rotationMatrix);
            
            float border = o.Alpha;
			border = GetPieceAlpha(IN.color.r, border, uv_Left);
			border = GetPieceAlpha(IN.color.g, border, uv_Right);
			border = GetPieceAlpha(IN.color.b, border, uv_Top);
			border = GetPieceAlpha(IN.color.a, border, uv_Bot);
			float edge = smoothstep(0.01,0.99,border);
//			float f = fwidth(edge) * 2;
//			float smoothEdge =smoothstep(-f, f, edge);
			
			fixed4 color = fixed4(edge * c.rgb +  (1 - edge) * _BorderColor.rgb, 1);
//            fixed4 color = fixed4(border,border,border,1);
			o.Albedo =adjustColor(color).rgb;
		}
		ENDCG
	}
	FallBack "Diffuse"
}