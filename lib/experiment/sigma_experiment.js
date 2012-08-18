dai=sigInst._core.graph.nodesIndex["1512230260"]
wei=sigInst._core.graph.nodesIndex["563900754"]

dai.color='#ffffff'
wei.color='#ffffff'



nodes=sigInst._core.graph.nodes;
edges=sigInst._core.graph.edges;

e1=null;
for(i=0; i<edges.length; i++){
    e=edges[i];
    if ( ((e.source.id == dai.id) && (e.target.id ==wei.id)) || ((e.target.id == dai.id) && (e.source.id ==wei.id)) ){
        e1=e;
        console.log(i);
        break;
    }
}
e1.size=1;
e1.color='#ffffff';


sigInst.draw();

for(i=0; i<edges.length; i++){
    e=edges[i];
    if (e.source.id == dai.id){
        e.color='#ffffff';
        e.size=1.0;
        console.log(i);
    }
}

sigInst.draw();

nodes=sigInst._core.graph.nodes;
edges=sigInst._core.graph.edges;

dai01=sigInst.getNodes("1512230260");
wei01=sigInst.getNodes("563900754");
dai01.color="#ffffff";
wei01.color="#ffffff";
sourceid=dai01.id;
targetid=wei01.id;
dai01.label="";
wei01.label="";
sigInst.addNode("01", dai01);
sigInst.addNode("02", wei01);

edgeid=sigInst._core.graph.edges.length;

var edge={
    id:     edgeid,
    sourceID: sourceid,
    targetID: targetid,
    size:      1,
    label:    null,
    color:    "#ffffff"
}

sigInst.addEdge(edge.id, sourceid, targetid, edge);
sigInst.draw(1,1,1);

sigInst.dropNode("01");
sigInst.dropNode("02");
sigInst.dropEdge(edgeid);
sigInst.draw(2,2,2);


window.overlayNodeID = 0;
window.overlayEdgeID=1000000;


function addOverlay(sID, tIDs){
    source=sigInst.getNodes(sID)

    if(sigInst._core.graph.nodesIndex[sID]){
        sourceNode=sigInst.getNodes(sID);
        sourceNode.label="";
        sourceNode.color="#ffffff";
        overlayNodeID++;
        sigInst.addNode(overlayNodeID.toString(), sourceNode);

        for(i=0; i<tIDs.length; i++){
            tID=tIDs[i];
            if(sigInst._core.graph.nodesIndex[sID]){
                targetNode=sigInst.getNodes(tID);
                targetNode.label="";
                targetNode.color="#ffffff";
                overlayNodeID++;
                sigInst.addNode(overlayNodeID.toString(), targetNode);

                overlayEdgeID++;
                var edge={
                    id:     overlayEdgeID,
                    sourceID: "1",
                    targetID: overlayNodeID,
                    size:      1,
                    label:    null,
                    color:    "#ffffff"
                }

                sigInst.addEdge(overlayEdgeID, "1", overlayNodeID, edge);

            }
        }
    }
    sigInst.draw(2,2,2)
}

window.sourceID = "1512230260"
window.targetIDs=["563900754","683129223","100002740581366", "123"]

addOverlay(sourceID, targetIDs);


function removeOverlay(){
    while(overlayEdgeID>1000000){
        sigInst.dropEdge(overlayEdgeID);
        overlayEdgeID--;
    }

    while(overlayNodeID>0){
        sigInst.dropNode(overlayNodeID);
        overlayNodeID--;
    }
    sigInst.draw(2,2,2)
}

removeOverlay();
