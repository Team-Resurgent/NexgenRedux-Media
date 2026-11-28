// A thread's script: takes rows of the Mandelbrot set to work out from "rows", and sends each back on "done": which
// picture, its number, then a byte for each pixel: how many steps it took to leave, or 255 for never.

void main()
{
    Channel rows("rows"), done("done");
    while (!Worker::stopping)
    {
        string job = rows.demand(0.5f);
        if (job.isEmpty()) continue;
        array<string>@ parts = job.split(" ");
        string picture = parts[0];
        uint y = parseUInt(parts[1]);
        uint width = parseUInt(parts[2]);
        uint height = parseUInt(parts[3]);
        double zoom = parseFloat(parts[4]);
        double cx = parseFloat(parts[5]);
        double cy = parseFloat(parts[6]);
        string row;
        row.resize(width);
        double ci = cy + (double(y) / height - 0.5) * zoom * height / width;
        for (uint x = 0; x < width; x++)
        {
            double cr = cx + (double(x) / width - 0.5) * zoom;
            double zr = 0, zi = 0;
            uint steps = 0;
            while (steps < 254 && zr * zr + zi * zi < 4)
            {
                double t = zr * zr - zi * zi + cr;
                zi = 2 * zr * zi + ci;
                zr = t;
                steps++;
            }
            row[x] = uint8(steps >= 254 ? 255 : steps);
        }
        done.push(picture + " " + formatUInt(y) + " " + row);
    }
}
