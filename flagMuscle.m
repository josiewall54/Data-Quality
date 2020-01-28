function muscleFlag = flagMuscle(metrics)
    
    if (metrics.SNR < 2 || metrics.baseNoise > 0.1 || metrics.sixtyNoise > 15)
        muscleFlag = 1;
    else
        muscleFlag = 0;
    end
    
end