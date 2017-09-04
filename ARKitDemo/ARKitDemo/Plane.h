//
//  Plane.h
//  ARKitDemo
//
//  Created by fanbo on 2017/9/4.
//  Copyright © 2017年 fanbo. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>

@interface Plane : SCNNode

@property (strong, nonatomic) ARPlaneAnchor *anchor;
@property (strong, nonatomic) SCNBox *planeGeometry;

-(id)initWithAnchor:(ARPlaneAnchor *)anchor isHidden:(BOOL)hidden;
-(void)update:(ARPlaneAnchor *)anchor;
@end
