//
//  Plane.m
//  ARKitDemo
//
//  Created by fanbo on 2017/9/4.
//  Copyright © 2017年 fanbo. All rights reserved.
//

#import "Plane.h"

@implementation Plane

-(id)initWithAnchor:(ARPlaneAnchor *)anchor isHidden:(BOOL)hidden
{
    self = [super init];
    self.anchor = anchor;
    float width = anchor.extent.x;
    float length = anchor.extent.z;
    // 使用 SCNBox 替代 SCNPlane 以便场景中的几何体与平面交互。
    // 为了让物理引擎正常工作，需要给平面一些高度以便场景中的几何体与其交互
    float planeHeight = 0.01;
    
    self.planeGeometry = [SCNBox boxWithWidth:width height:planeHeight length:length chamferRadius:0];
    SCNMaterial *material = [SCNMaterial new];
    UIImage *img = [UIImage imageNamed:@"tron_grid"];
    material.diffuse.contents = img;
    material.lightingModelName = SCNLightingModelPhysicallyBased;
    
    // 由于正在使用立方体，但却只需要渲染表面的网格，所以让其他几条边都透明
    SCNMaterial *transparentMaterial = [SCNMaterial new];
    transparentMaterial.diffuse.contents = [UIColor whiteColor];
    
    if (hidden) {
        self.planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial];
    }else{
        self.planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material, transparentMaterial];
    }
    
    SCNNode *planeNode = [SCNNode nodeWithGeometry:_planeGeometry];
    planeNode.position = SCNVector3Make(0, (-planeHeight / 2.0), 0);
    
    // SceneKit 里的平面默认是垂直的，所以需要旋转90度来匹配 ARKit 中的平面
    planeNode.transform = SCNMatrix4MakeRotation((-M_PI_2), 1.0, 0.0, 0.0);
    
    // 给平面物理实体，以便场景中的物体与其交互
    planeNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:_planeGeometry options:nil]];
    
    [self setTextureScale];
    [self addChildNode:planeNode];
    
    return self;
}

-(void)update:(ARPlaneAnchor *)anchor
{
    // 随着用户移动，平面 plane 的 范围 extend 和 位置 location 可能会更新。
    // 需要更新 3D 几何体来匹配 plane 的新参数。
    _planeGeometry.width = anchor.extent.x;
    _planeGeometry.height = anchor.extent.z;
    
    // plane 刚创建时中心点 center 为 0,0,0，node transform 包含了变换参数。
    // plane 更新后变换没变但 center 更新了，所以需要更新 3D 几何体的位置
    self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
    
    SCNNode *node = self.childNodes.firstObject;
    node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:[SCNPhysicsShape shapeWithGeometry:_planeGeometry options:nil]];
    
    
    [self setTextureScale];
}

-(void)setTextureScale
{
    float width = _planeGeometry.width;
    float height = _planeGeometry.height;
    
    // 平面的宽度/高度 width/height 更新时，我希望 tron grid material 覆盖整个平面，不断重复纹理。
    // 但如果网格小于 1 个单位，我不希望纹理挤在一起，所以这种情况下通过缩放更新纹理坐标并裁剪纹理
    SCNMaterial *material = _planeGeometry.materials.firstObject;
    material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1);
    material.diffuse.wrapS = SCNWrapModeRepeat;
    material.diffuse.wrapT = SCNWrapModeRepeat;

}

-(void)hide
{
    SCNMaterial *transparentMaterial = [SCNMaterial new];
    transparentMaterial.diffuse.contents = [UIColor whiteColor];
    self.planeGeometry.materials = @[transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial];
    
}

@end
