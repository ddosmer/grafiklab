






private void button1_Click(object sender, EventArgs e)
{
    Graphics g = Graphics.FromImage(newBitmap);
    g.Clear(SystemColors.Control);

    xa = Convert.ToInt32(textBox1.Text);
    ya = Convert.ToInt32(textBox2.Text);
    za = Convert.ToInt32(textBox3.Text);
    alfa = Convert.ToInt32(textBox4.Text);
    beta = Convert.ToInt32(textBox5.Text);
    teta = Convert.ToInt32(textBox6.Text);
    D = Convert.ToInt32(textBox7.Text);

    ttransformasyon(alfa, beta, teta);

    int x_m, z_m, i, j;
    double fonk_1, fonk_2, fonk_3, fonk_4, mod1, mod2;
    for (i = 0; i < 400; i++)
    {
        for (j = 0; j < 400; j++)
        {
            x_m = j - 200;
            z_m = -i + 200;
            K = (-za / payda);
            X = xa + K * (Rt[0, 0] * x_m + D * Rt[0, 1] + z_m * Rt[0, 2]);
            Y = ya + K * (Rt[1, 0] * x_m + D * Rt[1, 1] + z_m * Rt[1, 2]);
            payda = Rt[2, 0] * x_m + D * Rt[2, 1] + Rt[2, 2] * z_m;
            if (payda == 0)
                continue;

            if (K > 0)
            {
                fonk_1 = Math.Floor(X + 0.5);//Floor fonksiyonu ile sayılar yakın olan tam sayı değerine yuvarlanıyor.
                fonk_2 = Math.Floor(Y + 0.5);
                fonk_3 = texture.Width;
                fonk_4 = texture.Height;
                mod1 = Math.Abs(fonk_1 % fonk_3);
                mod2 = Math.Abs(fonk_2 % fonk_4);

                if (Y < 0)
                    mod2 = (int)(texture.Height - mod2) % texture.Height;

                if (X < 0)
                    mod1 = texture.Width - mod1 - 1;
                newBitmap.SetPixel(j, i, texture.GetPixel(Convert.ToInt32(mod1), Convert.ToInt32(mod2)));
            }
        }
    }
    pictureBox1.Image = newBitmap;
}
