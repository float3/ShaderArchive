static float debug;

#define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))

float vmin(float2 v)
{
    return min(v.x, v.y);
}

float vmax(float2 v)
{
    return max(v.x, v.y);
}

float ellip(float2 p, float2 s)
{
    float m = vmin(s);
    return (length(p / s) * m) - m;
}

float halfEllip(float2 p, float2 s)
{
    p.x = max(0., p.x);
    float m = vmin(s);
    return (length(p / s) * m) - m;
}


float fBox(float2 p, float2 b)
{
    return vmax(abs(p) - b);
}

float pupil(float2 p)
{
    float d = ellip(p, float2(0.5, 1));
    float d2 = ellip(p, float2(0.25, 0.5));
    return -max(-d, -d2 * 6);
    return d + d2;
}

float eye(float2 p)
{
    float d = ellip(p, float2(3, 1.5));
    float d2 = ellip(p, float2(2.7, 1));

    d = max(d, -d2);
    d2 = pupil(p);


    return min(d, d2);
}


float eyes(float2 p)
{
    float d = eye(p);
    
    d = min(d, eye(p));

    return -d;
}
