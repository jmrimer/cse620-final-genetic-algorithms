% option is for the function selection
% option=1: for M1 function
% option=4: for M4 function
% sigmash, alpha are the parameters for sharing

function [population, Fmax, Fmin, Faver, benchmark_function]=genetic( ...
    population_size, ...
    chromosome_length, ...
    benchmark_domain_start, ...
    benchmark_domain_end,...
    option, ...
    probability_of_crossover, ...
    probability_of_mutation, ...
    total_generations, ...
    does_crowding, ...
    does_sharing, elite, eliteSize, hybrid, sigmash, alpha,handles)


    [x, y] = initialize_graph_axes(option, benchmark_domain_start, benchmark_domain_end, handles);
    benchmark_function = setup_benchmark(option);
    plot(x,benchmark_function(x));
    
    elites = [];
    Fmax = zeros(1, total_generations);
    Fmin = zeros(1, total_generations);
    Faver = zeros(1, total_generations);
    
    population = initialise(population_size, chromosome_length, benchmark_domain_start, benchmark_domain_end, benchmark_function, option);
    plot_baseline_benchmark(option, population, chromosome_length);

    for j=1:total_generations
        if does_crowding==1
            population=crowding(population, population_size, chromosome_length, benchmark_domain_start, benchmark_domain_end, benchmark_function, option);
        end
        
        if does_sharing==1
            population = sharing(population, population_size, chromosome_length, option, sigmash, alpha);
        end
        
        population = calculate_fitness(population, population_size, chromosome_length, benchmark_function);
        [Fmax(j), Fmin(j), Faver(j)] = capture_generation_fitness_measures(population, chromosome_length);
        
        
    
        [ind1, ind2, wind1, wind2]=roulette(population, population_size, chromosome_length, option);%Selection methods
        
        parent1=population(ind1,:);
        parent2=population(ind2,:);
    
        child1 = parent1;
        child2 = parent2;
        
        if does_crowding~=1
            [child1, child2]=crossover(parent1, parent2, benchmark_domain_start, benchmark_domain_end, option, benchmark_function, chromosome_length, probability_of_crossover);%crossover
        end
        
        population = mutate_two_children(population, child1, child2, ...
            benchmark_domain_start, benchmark_domain_end, benchmark_function, ...
            chromosome_length, probability_of_mutation, ...
            wind1, wind2);
        
        elites = find_elites_from_pop(population, chromosome_length, eliteSize, elites);
        if elite == 1
           elitism(population, elites, eliteSize, chromosome_length);
        end
    end
    
    if option==1 || option==4
        xlabel('x');
        ylabel('M(x)');
        plot(population(:,chromosome_length+1),population(:,chromosome_length+2),'g*');
        hleg1=legend('Function','Initial Optimum','Niche Points','Location','Southeast');
    else
        xlabel('x');
        ylabel('M(x)');
        plot3(population(:,2*chromosome_length+2),population(:,2*chromosome_length+1),population(:,2*chromosome_length+3),'g*');
        title('Function and Population (initial,niched) plot')
        hleg1=legend('Function','Initial Optimum','Niche Points','Location','SoutheastOutside');
        
    end

    axes(handles.axes2);
    plot(Fmax), hold on, plot(Faver,'r-'), hold on, plot(Fmin,'g');
    xlabel('Generation')
    ylabel('Fitness')
    title('Fitness Progress')
    legend('Maximum Fitness','Mean Fitness','Minimum Fitness','Location', 'best')

end

%%%%%%%%%%%%%%%%%%
%End of function
%%%%%%%%%%%%%%%%%%

function plot_baseline_benchmark(option, pop, stringlength)
    if option==1 || option==4
        plot(pop(:,stringlength+1),pop(:,stringlength+2),'r*');
    else
        plot3(pop(:,2*stringlength+2),pop(:,2*stringlength+1),pop(:,2*stringlength+3),'w*');
    end
end

function [x, y] = initialize_graph_axes(option, a, b, handles)
    if option==1 || option==4
        x=a:0.01:b;
        y=a:0.01:b;
    else
        x=a:0.5:b;
        y=a:0.5:b;
    end
    
    axes(handles.axes1);
    cla;
end

function benchmark_function = setup_benchmark(option)
    switch option
        case 1
            benchmark_function= @(x) sin(5*pi*x).^6;        
            hold on
        case 4
            benchmark_function= @(x) exp(-2*log(2)*((x-0.08)/0.854).^2).*sin(5*pi*(x.^0.75-0.05)).^6;
            hold on
    end
end

function pop = calculate_fitness(pop, popsize, stringlength, benchmark_function)
    for i=1:popsize
        pop(i,stringlength+2)=benchmark_function(pop(i,stringlength+1));
    end
end

function [Fmax, Fmin, Faver] = capture_generation_fitness_measures(pop, stringlength)
    Fmax=max(pop(:,stringlength+2));
    Fmin=min(pop(:,stringlength+2));
    Faver=mean(pop(:,stringlength+2));
end

function elites = find_elites_from_pop(pop, stringlength, eliteSize, elites);
    maxFitness = maxk(pop(:,stringlength+2), eliteSize);

    for e=1:eliteSize
        for f=1:eliteSize
            if (size(elites, 1) < e || maxFitness(f) > elites(e, stringlength+2))
                matches = pop(pop(:,stringlength+2)==maxFitness(e),:);
                elites(e, :) = matches(1,:);
            end
        end
    end
end

function population = mutate_two_children(population, child1, child2, benchmark_domain_start, benchmark_domain_end, benchmark_function, chromosome_length, probability_of_mutation, wind1, wind2)
    child1m=mutation(child1, benchmark_domain_start, benchmark_domain_end, benchmark_function, chromosome_length, probability_of_mutation);%mutation
    child2m=mutation(child2, benchmark_domain_start, benchmark_domain_end, benchmark_function, chromosome_length, probability_of_mutation);
    
    population(wind1,:)=child1m;
    population(wind2,:)=child2m;
end