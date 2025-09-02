import React, { useCallback, useState } from 'react';
import ReactFlow, {
  MiniMap,
  Controls,
  Background,
  useNodesState,
  useEdgesState,
  addEdge,
  Connection,
  Edge,
  Node,
  BackgroundVariant,
} from 'reactflow';
import 'reactflow/dist/style.css';

// Custom Nodes
import T2VNode from '../nodes/T2VNode';
import I2VNode from '../nodes/I2VNode';
import TI2VNode from '../nodes/TI2VNode';
import S2VNode from '../nodes/S2VNode';
import UpscaleNode from '../nodes/UpscaleNode';
import OutputNode from '../nodes/OutputNode';

const nodeTypes = {
  t2v: T2VNode,
  i2v: I2VNode,
  ti2v: TI2VNode,
  s2v: S2VNode,
  upscale: UpscaleNode,
  output: OutputNode,
};

const initialNodes: Node[] = [
  {
    id: '1',
    type: 't2v',
    position: { x: 100, y: 100 },
    data: { 
      label: 'Text to Video',
      model: 'Wan2.2-T2V-A14B',
      prompt: '',
      resolution: '720p',
      duration: 5
    },
  },
  {
    id: '2',
    type: 'upscale',
    position: { x: 400, y: 100 },
    data: { 
      label: 'AI Upscale',
      scale: 2,
      model: 'RealESRGAN'
    },
  },
  {
    id: '3',
    type: 'output',
    position: { x: 700, y: 100 },
    data: { 
      label: 'Output',
      format: 'mp4',
      codec: 'h265'
    },
  },
];

const initialEdges: Edge[] = [
  { id: 'e1-2', source: '1', target: '2', animated: true },
  { id: 'e2-3', source: '2', target: '3', animated: true },
];

const NodeEditor: React.FC = () => {
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);
  const [, setSelectedNode] = useState<Node | null>(null);

  const onConnect = useCallback(
    (params: Connection) => setEdges((eds) => addEdge(params, eds)),
    [setEdges]
  );

  const onNodeClick = useCallback((_event: React.MouseEvent, node: Node) => {
    setSelectedNode(node);
  }, []);

  const onDragOver = useCallback((event: React.DragEvent) => {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
  }, []);

  const onDrop = useCallback(
    (event: React.DragEvent) => {
      event.preventDefault();

      const type = event.dataTransfer.getData('application/reactflow');
      if (!type) return;

      const reactFlowBounds = event.currentTarget.getBoundingClientRect();
      const position = {
        x: event.clientX - reactFlowBounds.left,
        y: event.clientY - reactFlowBounds.top,
      };

      const newNode: Node = {
        id: `${Date.now()}`,
        type,
        position,
        data: { label: `${type} node` },
      };

      setNodes((nds) => nds.concat(newNode));
    },
    [setNodes]
  );

  return (
    <div style={{ width: '100%', height: '100%' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onNodeClick={onNodeClick}
        onDrop={onDrop}
        onDragOver={onDragOver}
        nodeTypes={nodeTypes}
        fitView
      >
        <Controls />
        <MiniMap />
        <Background variant={BackgroundVariant.Dots} gap={12} size={1} />
      </ReactFlow>
    </div>
  );
};

export default NodeEditor;