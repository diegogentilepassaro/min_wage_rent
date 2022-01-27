program offset_x_axis
    syntax, [k(real 0.15)]
    cap drop at_r at_l
    gen at_r = at + `k'
    gen at_l = at - `k'
end
