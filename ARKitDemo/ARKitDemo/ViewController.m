//
//  ViewController.m
//  ARKitDemo
//
//  Created by fanbo on 2017/9/4.
//  Copyright © 2017年 fanbo. All rights reserved.
//

#import "ViewController.h"
#import "Plane.h"

//struct CollisionCategory {
//    int rawValue;
//    static int bottom = CollisionCategory(rawValue: 1 << 0);
//    static int cube = CollisionCategory(rawValue: 1 << 1);
//};


@interface ViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;

@end


@implementation ViewController
{
    NSMutableDictionary *_planes;
    NSMutableArray *_boxs;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _planes = [[NSMutableDictionary alloc] init];
    _boxs = [[NSMutableArray alloc] init];
    
    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    self.sceneView.autoenablesDefaultLighting = YES;
    // 开启 debug 选项以查看世界原点并渲染所有 ARKit 正在追踪的特征点
    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin | ARSCNDebugOptionShowFeaturePoints;
    
    
    // Create a new scene
    //    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    // 存放所有 3D 几何体的容器
    SCNScene *scene = [SCNScene new];
    //    // 想要绘制的 3D 立方体
    //    SCNBox *boxGeometry = [SCNBox boxWithWidth:0.1 height:0.1 length:0.1 chamferRadius:0];
    //    // 将几何体包装为 node 以便添加到 scene
    //    SCNNode *boxNode = [SCNNode nodeWithGeometry:boxGeometry];
    //    // 把 box 放在摄像头正前方
    //    boxNode.position = SCNVector3Make(0, 0, -0.5);
    //    // rootNode 是一个特殊的 node，它是所有 node 的起始点
    //    [scene.rootNode addChildNode:boxNode];
    // Set the scene to the view
    self.sceneView.scene = scene;
    
    
    // 轻点一下就会往场景中插入新的几何体
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    tap.numberOfTapsRequired = 1;
    [self.sceneView addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingSessionConfiguration *configuration = [ARWorldTrackingSessionConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


-(void)handleTapFrom:(UITapGestureRecognizer *)tap
{
    // 获取屏幕空间坐标并传递给 ARSCNView 实例的 hitTest 方法
    CGPoint tapPoint = [tap locationInView:self.sceneView];
    NSArray *result = [self.sceneView hitTest:tapPoint types:ARHitTestResultTypeExistingPlane];
    
    // 如果射线与某个平面几何体相交，就会返回该平面，以离摄像头的距离升序排序
    // 如果命中多次，用距离最近的平面
    //    if let hitResult = result.first {
    //        insertGeometry(hitResult)
    //    }
    ARHitTestResult *hitResult = result.firstObject;
    [self insertGeometry:hitResult];
}

-(void)insertGeometry:(ARHitTestResult *)hitResult
{
    CGFloat dimension = 0.1;
    SCNBox *cube = [SCNBox boxWithWidth:dimension height:dimension length:dimension chamferRadius:0];
    SCNNode *node = [SCNNode nodeWithGeometry:cube];
    // physicsBody 会让 SceneKit 用物理引擎控制该几何体
    node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
    node.physicsBody.mass = 2;
    node.physicsBody.categoryBitMask = 1 << 1;
    
    // 把几何体插在用户点击的点再稍高一点的位置，以便使用物理引擎来掉落到平面上
    CGFloat insertionYOffset = 0.5;
    node.position = SCNVector3Make(hitResult.worldTransform.columns[3].x, hitResult.worldTransform.columns[3].y+insertionYOffset, hitResult.worldTransform.columns[3].z);
    [self.sceneView.scene.rootNode addChildNode:node];
    [_boxs addObject:node];
}

#pragma mark - ARSCNViewDelegate

-(void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    Plane *plane = [[Plane alloc] initWithAnchor:(ARPlaneAnchor *)anchor isHidden:NO];
    [_planes setObject:plane forKey:anchor.identifier];
    [node addChildNode:plane];
}

/**
 有新的 node 被映射到给定的 anchor 时调用。
 @param renderer 将会用于渲染 scene 的 renderer。
 @param node   映射到 anchor 的 node。
 @param anchor 新添加的 anchor。
 */
// Override to create and configure nodes for anchors added to the view's session.
//- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
//    SCNNode *node = [SCNNode new];
//
//
//    return node;
//}

/**
 使用给定 anchor 的数据更新 node 时调用。
 
 @param renderer 将会用于渲染 scene 的 renderer。
 @param node 更新后的 node。
 @param anchor 更新后的 anchor。
 */
-(void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    Plane *plane = _planes[anchor.identifier];
    [plane update:(ARPlaneAnchor *)anchor];
}

-(void)renderer:(id<SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    [_planes removeObjectForKey:anchor.identifier];
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

@end

