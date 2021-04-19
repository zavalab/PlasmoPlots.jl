#TODO other plotting options:  plot bipartite, node-pins, or clique-graph
"""
    Plots.plot(graph::OptiGraph; node_labels = false, subgraph_colors = false, node_colors = false, linewidth = 2.0,linealpha = 1.0, markersize = 30,labelsize = 20, markercolor = :grey,
    layout_options = Dict(:tol => 0.01,:C => 2, :K => 4, :iterations => 2),
    plt_options = Dict(:legend => false,:framestyle => :box,:grid => false,:size => (800,800),:axis => nothing),
    line_options = Dict(:linecolor => :blue,:linewidth => linewidth,:linealpha => linealpha))

Plot a graph layout of the optigraph `graph`. The following keyword arguments can be provided to customize the graph layout.

* `node_labels = false`: whether to label nodes using the corresponding optinode label attribute.
* `subgraph_colors = false`: whether to color nodes according to their subgraph.
* `node_colors = false`: whether to color nodes.  Only active if `subgraph_colors = false`.
* `linewidth = 2.0`: the linewidth attribute for each edge in `graph`.
* `linealpha = 1.0`: the linealpha attribute for each edge in `graph`.
* `markersize = 30`: the markersize which determines the size of each node in `graph`.
* `labelsize = 20`: the size for each node label.  Only active if `node_labels = true`.
* `markercolor = :grey`: the color for each node.

* `layout_options = Dict(:tol => 0.01,:C => 2, :K => 4, :iterations => 2)`: dictionary with options for the layout algorithm.
    * `tol`: permitted distance between a current and calculated co-ordinate.
    * `C`,`K`: scaling parameters.
    * `iterations`: number of iterations used to apply forces.
* `plt_options = Dict(:legend => false,:framestyle => :box,:grid => false,:size => (800,800),:axis => nothing)`: dictionary with primary plotting options.
    * `legend`: whether to include legend, or legend position.
    * `framestyle`: style of frame used for plot.
    * `size`: size of the resulting plot.
    * `axis`: whether to include the axis.  The axis typically does not make sense for a graph layout plot.
    * It is also possible to use various plotting options compatible with `Plots.scatter` from the `Plots.jl` package.
* `line_options = Dict(:linecolor => :blue,:linewidth => linewidth,:linealpha => linealpha)`: line plotting options used to display edges in the graph.
    * `linecolor`: color to use for each line.
    * `linewidth`: linewidth to use for each edge.  Defaults to the above option.
    * `linealpha`: linealpha to use for each edge. Default to the above option.
"""
function Plots.plot(graph::OptiGraph; node_labels = false, subgraph_colors = false, node_colors = false, linewidth = 2.0, linealpha = 1.0, markersize = 30,labelsize = 20, markercolor = :grey,
    layout_options = Dict(:tol => 0.01, :C => 2, :K => 4, :iterations => 2),
    plt_options = Dict(:legend => false,:framestyle => :box,:grid => false,:size => (800,800),:axis => nothing),
    line_options = Dict(:linecolor => :blue,:linewidth => linewidth,:linealpha => linealpha))

    if subgraph_colors
        markercolor = []
        n_graphs = length(graph.subgraphs) + 1
        cols = Colors.distinguishable_colors(n_graphs)
        if cols[1] == Colors.parse(Colorant,"black")
            cols[1] = Colors.parse(Colorant,"grey")
        end
        for node in getnodes(graph)
            push!(markercolor,cols[1])
        end
        i = 2
        for subgraph in getsubgraphs(graph)
            for node in all_nodes(subgraph)
                push!(markercolor,cols[i])
            end
            i += 1
        end

    elseif node_colors
        cols = Colors.distinguishable_colors(length(all_nodes(graph)) + 1)
        if cols[1] == Colors.parse(Colorant,"black")
            cols[1] = Colors.parse(Colorant,"grey")
        end
        markercolor = cols[2:end]
    else
        markercolor = markercolor
    end

    #hypergraph,hyper_map = hyper_graph(graph)
    # clique_graph,clique_map = clique_expansion(hypergraph)
    clique_graph,clique_map = Plasmo.clique_graph(graph)
    lgraph = clique_graph#.lightgraph

    startpositions = Array{Point{2,Float32},1}()
    for i = 1:LightGraphs.nv(lgraph)
        push!(startpositions,Point(rand(),rand()))
    end
    mat = LightGraphs.adjacency_matrix(lgraph)
    positions = SFDP.layout(mat,Point2f0,startpositions = startpositions;layout_options...)

    #marker colors should be based on subgraphs
    scat_plt = Plots.scatter(positions;markersize = markersize,markercolor = markercolor,plt_options...);

    if node_labels
        for (i,node) in enumerate(all_nodes(graph))
            pos = positions[i]
            Plots.annotate!(scat_plt,pos[1],pos[2],Plots.text(node.label,labelsize))
        end
    end

    for edge in edges(lgraph)
        n_from_index = edge.src
        n_to_index = edge.dst
        Plots.plot!(scat_plt,[positions[n_from_index][1],positions[n_to_index][1]],[positions[n_from_index][2],positions[n_to_index][2]];line_options...)
    end

    return scat_plt
end




#Overlap plots
function Plots.plot(graph::OptiGraph,subgraphs::Vector{OptiGraph}; node_labels = false,linewidth = 2.0, linealpha = 1.0,markersize = 30,labelsize = 20, markercolor = :grey,
    layout_options = Dict(:tol => 0.01,:C => 2, :K => 4, :iterations => 2), plt_options = Dict(:legend => false,:framestyle => :box,:grid => false,
    :size => (800,800),:axis => nothing),line_options = Dict(:linecolor => :blue,:linewidth => linewidth,:linealpha => linealpha))

    nodes = all_nodes(graph)


    #COLORS
    markercolors = []
    markersizes = []
    n_graphs = length(subgraphs)
    cols = Colors.distinguishable_colors(n_graphs)
    if cols[1] == Colors.parse(Colorant,"black")
        cols[1] = Colors.parse(Colorant,"grey")
    end

    #subgraph_colors = Dict()
    node_colors = Dict((node,[]) for node in all_nodes(graph))


    for (i,subgraph) in enumerate(subgraphs)
        for node in all_nodes(subgraph)
            push!(node_colors[node],cols[i])
        end
    end

    #Now average node colors
    for node in all_nodes(graph)
        if haskey(node_colors,node)
            node_cols = node_colors[node]
            ave_r = mean([node_cols[i].r for i = 1:length(node_cols)])
            ave_g = mean([node_cols[i].g for i = 1:length(node_cols)])
            ave_b = mean([node_cols[i].b for i = 1:length(node_cols)])

            new_col = RGB(ave_r,ave_g,ave_b)
            push!(markercolors,new_col)
            if length(node_cols) > 1
                push!(markersizes,markersize*2)
            else
                push!(markersizes,markersize)
            end
        else
            push!(markercolors,Colors.parse(Colorant,"grey"))
            push!(markersizes,markersize)
        end
    end


    #LAYOUT
    hypergraph,hyper_map = gethypergraph(graph)
    clique_graph,clique_map = clique_expansion(hypergraph)
    lgraph = clique_graph#.lightgraph


    startpositions = Array{Point{2,Float32},1}()
    for i = 1:LightGraphs.nv(lgraph)
        push!(startpositions,Point(rand(),rand()))
    end
    mat = LightGraphs.adjacency_matrix(lgraph)
    positions = SFDP.layout(mat,Point2f0,startpositions = startpositions;layout_options...)

    #marker colors should be based on subgraphs
    scat_plt = Plots.scatter(positions;markersize = markersizes,markercolor = markercolors,plt_options...);

    if node_labels
        for (i,node) in enumerate(all_nodes(graph))
            pos = positions[i]
            Plots.annotate!(scat_plt,pos[1],pos[2],Plots.text(node.label,labelsize))
        end
    end

    for edge in edges(lgraph)
        n_from_index = edge.src
        n_to_index = edge.dst
        Plots.plot!(scat_plt,[positions[n_from_index][1],positions[n_to_index][1]],[positions[n_from_index][2],positions[n_to_index][2]];line_options...)
    end

    return scat_plt
end
