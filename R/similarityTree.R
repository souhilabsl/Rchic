#' @title Computes and Displays the Similarity Tree.
#'
#' @description (Reads the ASI rules) Computes the similarities and displays the Similarity Tree.
#' 
#' @param   list.variables  list of variables to compute the similarity tree from
#' @param   rules           dataframe of ASI rules.
#' @param   verbose         give many details
#'
#' @author Rapha\"{e}l Couturier \email{raphael.couturier@@univ-fcomte.fr}
#' @export


similarityTree <-function( list.variables, rules = NULL, Verbose=FALSE ) {
  
  rules = read.table(file='transaction.out',header=TRUE,row.names=1,sep=',',stringsAsFactors=F)
  row=row.names(rules)
  rules=as.data.frame(lapply(rules,as.numeric))
  row.names(rules)=row
  n     = dim(rules)[1]
  
  verbose<<-Verbose
  
  max.length.variables=max(str_length(list.variables))
  
  #data frame containing all the similarities
  similarity_matrix=matrix(nrow=length(list.variables),ncol=length(list.variables))
  colnames(similarity_matrix)=list.variables
  rownames(similarity_matrix)=list.variables
  
  #list of the occurrences of the variables
  list.occurrences.variables<<-vector()
  
  for(i in 1:n) {
    rule=strsplit(row.names(rules)[i],split=' -> ')
    from=rule[[1]][1]
    to=rule[[1]][2]
    val=rules[i,7]
    similarity_matrix[from,to]=val
    
    list.occurrences.variables[from]<<-rules[i,1]
  }
  
  
  
  
  
  similarity_matrix[is.na(similarity_matrix)]=0 
  
  
  
  
  #we need to use values between 0 and 1
  similarity_matrix<<-similarity_matrix/100
  
  
  
  
  
  #currently we consider that all items are selected
  list.selected.item=rep_len(T,length(list.variables))
  list.tcl<<-lapply(list.selected.item,function(i) tclVar(i))
  
  toolbarItem(list.variables,list.tcl,callPlotSimilarityTree)  
  
  #   #try to convert our tree to use it with the plot function of R
  #   merge=array(0,c(nb.levels,2))
  #   in.class=array(0,length(list.simi.indexes.variable))
  #   for(i in 1:nb.levels) {
  #     if (in.class[variable.left[i]]==0) {
  #       merge[i,1]=-variable.left[i]
  #     }
  #     else
  #       merge[i,1]=in.class[variable.left[i]]
  #     in.class[variable.left[i]]=i
  #     
  #     if (in.class[variable.right[i]]==0) {
  #       merge[i,2]=-variable.right[i]
  #     }
  #     else
  #       merge[i,2]=in.class[variable.right[i]]
  #     in.class[variable.right[i]]=i
  #   }
  #   order=list.simi.indexes.variable
  #   labels=list.simi.variables
  #   height=1:nb.levels
  #   tree=list(merge=merge,height=height,order=order,labels=labels,method='complete',call='test',dist.method='euclidian')
  #   attr(tree,'class')='hclust'
  #   plot(tree)
  
  
  
  visibleWidth=1200
  visibleHeight=800
  
  workingWidth=1200
  workingHeight=800
  
  
  
  tt <- tktoplevel()
  xscr <<- tkscrollbar(tt, orient="horizontal",
                      command=function(...)tkyview(canvas,...))
  
  yscr <<- tkscrollbar(tt, orient="vertical",
                      command=function(...)tkyview(canvas,...))
  
  
  
  
  
  
  canvas <<- tkcanvas(tt, relief="raised", width=visibleWidth, height=visibleHeight,
                     xscrollcommand=function(...)tkset(xscr,...), 
                     yscrollcommand=function(...)tkset(yscr,...), 
                     scrollregion=c(0,0,workingWidth,workingHeight))
  tkconfigure(xscr, command = function(...) tkxview(canvas, ...))
  tkconfigure(yscr, command = function(...) tkyview(canvas, ...))
  #tkconfigure(canvas, xscrollcommand = function(...) tkset(xscr, ...))
  #tkconfigure(canvas, yscrollcommand = function(...) tkset(yscr, ...))
  
  tkpack(xscr, side = "bottom", fill = "x")
  tkpack(yscr, side = "right", fill = "y")
  tkpack(canvas, side = "left", fill="both", expand=1)
  
  callPlotSimilarityTree()
  
}




callPlotSimilarityTree <- function() {
  
  
  list.selected.item=unlist(lapply(list.tcl,function(i) as.logical(as.numeric(tclvalue(i)))))
  
  
    
  max.length.variables=max(str_length(list.variables))
  
  #extract sub matrix and sub list according to selected items
  sub_matrix=similarity_matrix[list.selected.item,list.selected.item]
  sub.list.item=rep(T,sum(list.selected.item))
  sub.list.occ=list.occurrences.variables[list.selected.item]
  
  
  #call the similarity computation written in C
  res=callSimilarityComputation(sub_matrix,sub.list.occ,verbose)
  
  list.simi.indexes.variable=res[[1]][[1]]
  list.simi.variables=res[[1]][[2]]
  
  #name of variables to create the classes
  variable.left=res[[2]]    #variable.left=tabo
  variable.right=res[[3]]   #variable.right=tabz
  
  nb.levels=res[[4]]
  
  list.significant.nodes=res[[5]]
  
  #remove the () in the classes and convert the indexes from char to integer
  list.simi.indexes.variable=str_replace_all(list.simi.indexes.variable,"([())])","")
  list.simi.indexes.variable=strsplit(list.simi.indexes.variable,' ')
  list.simi.indexes.variable=as.integer(list.simi.indexes.variable[[1]])
  
  #remove the () and create a list of the variable in the order that they need to be displayed
  list.simi.variables=str_replace_all(list.simi.variables,"([())])","")
  list.simi.variables=strsplit(list.simi.variables,' ')
  list.simi.variables=list.simi.variables[[1]]
  
  
  #print(list.simi.variables)
  
  offsetX=10
  offsetY=30
  
  dx=20
  dy=10
  
  visibleWidth=1200
  visibleHeight=800
  
  workingWidth=length(list.simi.variables)*dx+50
  workingHeight=offsetY+10*(max.length.variables)+nb.levels*dy+50
  
  offset.variable.x=0
  offset.variable.y=0
  
  inc=1
  for(i in 1:length(list.simi.indexes.variable)){
    offset.variable.x[list.simi.indexes.variable[i]]=offsetX+dx*i
    offset.variable.y[i]=offsetY+10*max.length.variables+10
  }
  
  
  
  
  
  plotFont <- "Helvetica 8"
  
  
  
  tkconfigure(canvas, scrollregion=c(0,0,workingWidth,workingHeight))
  
  tkdelete(canvas, "draw")
  
  level=0
  
  #print(list.simi.variables)
  for (i in 1:length(list.simi.variables)) {
    #length of current variable
    length.variable=str_length(list.simi.variables[i])
    #offset compared to the lenghtest variable
    offset.length.variable=max.length.variables-length.variable
    for (j in 1:str_length(list.simi.variables[i])) {
      tkcreate(canvas, "text", offsetX+i*dx, offsetY+10*(offset.length.variable+j), text=substr(list.simi.variables[i],j,j),font=plotFont, fill="brown",tags="draw")
    }
  }
  
  offsetY=offsetY+10*max.length.variables+10
  plotFont= "Helvetica 8"
  
  
  line.coord=numeric(4)
  for (j in 1:nb.levels) {
    #for (j in 1:12) {  
    
    y2=dy*j+offsetY;
    line.coord[1]=offset.variable.x[variable.left[j]]   #tabz = offset.variable.x
    line.coord[2]=offset.variable.y[variable.left[j]]   #tabh = offset.variable.y
    line.coord[3]=offset.variable.x[variable.left[j]]
    line.coord[4]=y2
    #draw the left horizontal line
    tkcreate(canvas, "line", line.coord,width=2,tags="draw")
    
    line.coord[1]=offset.variable.x[variable.left[j]]
    line.coord[2]=y2
    line.coord[3]=offset.variable.x[variable.right[j]]
    line.coord[4]=y2
    
    #draw the vertical line
    if(list.significant.nodes[j])    
      tkcreate(canvas, "line", line.coord,width=2,tags="draw",fill="red")
    else
      tkcreate(canvas, "line", line.coord,width=2,tags="draw")
    
    
    line.coord[1]=offset.variable.x[variable.right[j]]
    line.coord[2]=y2
    line.coord[3]=offset.variable.x[variable.right[j]]
    line.coord[4]=offset.variable.y[variable.right[j]]
    
    #draw the right line
    tkcreate(canvas, "line", line.coord,width=2,tags="draw")
    
    
    offset.variable.x[variable.left[j]]=(offset.variable.x[variable.left[j]]+offset.variable.x[variable.right[j]])/2
    
    offset.variable.x[variable.right[j]]=offset.variable.x[variable.left[j]]
    
    offset.variable.y[variable.left[j]]=y2
    
    
    
    offset.variable.y[variable.right[j]]=y2
    
    
    
  }
  
  
  
  
}





