#version 400

#define M_PI 3.1415926535

uniform int selection;
uniform double screen_ratio;
uniform dvec2 screen_size;
uniform dvec2 center;
uniform dvec2 orbit_trap;
uniform double zoom;
uniform int iterations;
uniform vec3 color_mod;

uniform float kda;
uniform float kdb;
uniform float kdc;
uniform float kdd;
uniform float startx;
uniform float starty;

uniform float uf_min;

uniform sampler2D sampler;

out vec4 colorOut;

const vec3 color_map[] = 
{
    {0.0,  0.0,  0.0},
    {0.26, 0.18, 0.06},
    {0.1,  0.03, 0.1},
    {0.04, 0.0,  0.18},
    {0.02, 0.02, 0.29},
    {0.0,  0.03, 0.37},
    {0.04, 0.13, 0.60},
    {0.07, 0.32, 0.75},
    {0.22, 0.49, 0.82},
    {0.52, 0.71, 0.9},
    {0.82, 0.92, 0.97},
    {0.94, 0.91, 0.75},
    {0.97, 0.79, 0.37},
    {1.0,  0.60, 0.0},
    {0.8,  0.5,  0.0},
    {0.6,  0.30, 0.0},
    {0.41, 0.2,  0.01}
};

float map(float value, float min1, float max1, float min2, float max2)
{
    float perc = (value - min1) / (max1 - min1);
    return perc * (max2 - min2) + min2;
}

vec4 point_orbit_trap(dvec2 c)
{
    dvec2 z;
    int i;
    double dist = 1E20;
    for(i = 0; i < iterations; i++)
    {
        double x = (z.x * z.x - z.y * z.y) + c.x;
        double y = (z.y * z.x + z.x * z.y) + c.y;

        if((x*x + y*y) > 4.0) break;
        z.x = x;
        z.y = y;

        dist = min(dist, length(z - orbit_trap));
    }
    float d = float(dist);
    if(iterations == i) return vec4(vec3(0.0), 1.0);
    return vec4(dist, sin(d*20), cos(d)*10, 1.0);
}

vec4 pickover_stalks(dvec2 c)
{
    dvec2 z;
    int i;
    double dist = 1E20;
    for(i = 0; i < iterations; i++)
    {
        double x = (z.x * z.x - z.y * z.y) + c.x;
        double y = (z.y * z.x + z.x * z.y) + c.y;

        if((x*x + y*y) > 4.0) break;
        z.x = x;
        z.y = y;

        double dx = abs(z.x - orbit_trap.x);
        double dy = abs(z.y - orbit_trap.y);
        double smallest = min(dx, dy);
        dist = min(dist, smallest);
    }
    float d = float(dist);
    return vec4(dist, sin(d*20), sin(d)*10, 1.0);
}

vec4 iteration_map(dvec2 c)
{
    dvec2 z;
    int i;
    for(i = 0; i < iterations; i++)
    {
        double x = (z.x * z.x - z.y * z.y) + c.x;
        double y = (z.y * z.x + z.x * z.y) + c.y;
        if((x*x + y*y) > 4.0) break;
        z.x = x;
        z.y = y;
    }
    double t = double(i) / double(iterations);
    uint row_i = (i * 100 / iterations % 17);
    return vec4((i == iterations ? vec3(0.0) : color_map[row_i]), 1.0);
}

vec4 normalized_colors(dvec2 c)
{
    dvec2 z;
    int i;
    double x, y;
    for(i = 0; i < iterations; i++)
    {
        if((x*x + y*y) > 4.0) break;
        x = (z.x * z.x - z.y * z.y) + c.x;
        y = (z.y * z.x + z.x * z.y) + c.y;
        z.x = x;
        z.y = y;
    }
    
    if(i == iterations)
    {
        return vec4(0.0);
    }

    float nsmooth = i + 1 - log(log(float(z.x*z.x + z.y*z.y)))/log(2);
    float r = (1.0) / (100);
    float ry = (nsmooth - 1.0) * r;
    return vec4(ry * color_mod.x, ry * color_mod.y, ry * color_mod.z, 1.0);
}

vec4 kings_dream(dvec2 c)
{
    vec2 cc = vec2(c);
    float x, y, xp = startx, yp = starty;
    for(int i = 0; i < iterations; i++)
    {
        x = sin(yp * kdb) + kdc * sin(xp * kdb) + cc.x;
        y = sin(xp * kda) + kdd * sin(yp * kda) + cc.y;
        xp = x;
        yp = y;
    }
    return vec4(map(x, 0.0, 1.0, 0, 800), map(y, 0.0, 1.0, 0, 800), 0.0, 1.0);
}

vec2 cmul(vec2 a, vec2 b)
{
    return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x);
}

vec2 ccos(vec2 a)
{
    return vec2(cos(a.x)*cosh(a.y), -sin(a.x)*sinh(a.y));
}

vec4 unknown_fractal(dvec2 c)
{
    vec2 z = vec2(c);
    double d;
    int i = 0, n = 0;
    for(i = 0; i < iterations; i++)
    {
        d = length(z);
        if(d > uf_min)
        {
            n = i;
            break;
        }
        z = (vec2(1.0,0.0) + 4.0 * z - cmul(vec2(1.0,0.0) + 2.0 * z, ccos(M_PI * z))) / 4.0;
    }
    float t = log(float(n + 1)) / log(float(iterations));
    return vec4(float(n != 0) * vec3(sqrt(t), t, 1.0 - sqrt(t)),1.0);
}

vec4 getImageColor(vec2 p)
{
    return texture(sampler, p).rgba;
}

vec4 image_fractal(dvec2 c)
{
    dvec2 z;
    vec4 col;
    int i;
    for(i = 0; i < iterations; i++)
    {
        double x = (z.x * z.x - z.y * z.y) + c.x;
        double y = (z.y * z.x + z.x * z.y) + c.y;
        if((x*x + y*y) > 4.0) break;
        z.x = x;
        z.y = y;
        col = getImageColor(vec2(z));
    }
    if(iterations == i)
        return vec4(0.0, 0.0, 0.0, 1.0);
    else
        return col;
}

vec4 burning_ship(dvec2 c)
{
    dvec2 z = dvec2(c);
    int i;
    while(z.x*z.x + z.y*z.y < 4.0 && i < iterations)
    {
        double xtemp = z.x*z.x - z.y*z.y + c.x;
        z.y = abs(2*z.x*z.y) + c.y;
        z.x = abs(xtemp);
        i++;
    }
    if(i == iterations)
        return vec4(0.0, 0.0, 0.0, 1.0);
    return vec4(mod(i * 0.4, 1.0), mod(i * 0.2, 1.0), mod(i * 0.8, 1.0), 1.0);
}

void main()
{
    dvec2 c;
    c.x = screen_ratio * (gl_FragCoord.x / screen_size.x - 0.5);
    c.y = screen_ratio * (gl_FragCoord.y / screen_size.y - 0.5);

    c.x /= zoom;
    c.y /= zoom;

    c.x += center.x;
    c.y += center.y;

    if(selection == 0)
    {
        colorOut = pickover_stalks(c);
    }
    else if(selection == 1)
    {
        colorOut = iteration_map(c);
    }
    else if(selection == 2)
    {
        colorOut = point_orbit_trap(c);
    }
    else if(selection == 3)
    {
        colorOut = normalized_colors(c);
    }
    else if(selection == 4)
    {
        colorOut = kings_dream(c);
    }
    else if(selection == 5)
    {
        colorOut = unknown_fractal(c);
    }
    else if(selection == 6)
    {
        colorOut = image_fractal(c);
    }
    else if(selection == 7)
    {
        colorOut = burning_ship(c);
    }
}