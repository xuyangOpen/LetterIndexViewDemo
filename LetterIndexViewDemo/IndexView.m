//
//  IndexView.m
//  LetterIndexViewDemo
//
//  Created by imac on 2017/10/12.
//  Copyright © 2017年 ms. All rights reserved.
//

#import "IndexView.h"
#import "SectionIndicatorView.h"

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

@interface IndexView ()

@property (nonatomic, strong) SectionIndicatorView *indicatorView;

@property (nonatomic, copy) NSArray<NSString *> *indexItems;                        /**< 组标题数组 */
@property (nonatomic, strong) NSMutableArray<UILabel *> *itemsViewArray;            /**< 标题视图数组 */
@property (nonatomic, assign) NSInteger selectedIndex;                              /**< 当前选中下标 */
@property (nonatomic, assign) CGFloat minY;                                         /**< Y坐标最小值 */
@property (nonatomic, assign) CGFloat maxY;                                         /**< Y坐标最大值 */
@property (nonatomic, assign) CGSize itemMaxSize;                                   /**< item大小，参照W大小设置 */
@property (nonatomic, strong) UIImageView *selectedImageView;                       /**< 当前选中item的背景圆 */
@property (nonatomic, assign) BOOL isCallback;                                      /**< 是否需要调用代理方法，如果是scrollView自带的滚动，则不需要触发代理方法，如果是滑动指示器视图，则触发代理方法 */
@property (nonatomic, assign) BOOL isShowIndicator;                                 /**< 是否显示指示器，只有触摸标题，才显示指示器 */
@property (nonatomic, assign) BOOL isAnimating;                                     /**< 是否在进行动画 */

@property (nonatomic, assign) BOOL isUpScroll;                                      /**< 是否是上拉滚动 */
@property (nonatomic, assign) BOOL isFirstLoad;                                     /**< 是否第一次加载tableView */
@property (nonatomic, assign) CGFloat oldY;                                         /**< 滚动的偏移量 */
@property (nonatomic, assign) BOOL isAllowedChange;                                 /**< 是否允许改变当前组 */

@end

@implementation IndexView

#pragma mark - 数据源方法
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        return [self.dataSource numberOfSectionsInTableView:tableView];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
        return [self.dataSource tableView:tableView numberOfRowsInSection:section];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]) {
        return [self.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return nil;
}

#pragma mark - 代理方法
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [self.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [self.delegate tableView:tableView heightForHeaderInSection:section];
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
        return [self.delegate tableView:tableView viewForHeaderInSection:section];
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if(self.isAllowedChange && !self.isUpScroll && !self.isFirstLoad) {
        //最上面组头（不一定是第一个组头，指最近刚被顶出去的组头）又被拉回来
        [self setSelectionIndex:section];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section {
    if (self.isAllowedChange && !self.isFirstLoad && self.isUpScroll) {
        //最上面的组头被顶出去
        [self setSelectionIndex:section + 1];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y > self.oldY) {
        self.isUpScroll = YES;      // 上滑
    }
    else {
        self.isUpScroll = NO;       // 下滑
    }
    self.isFirstLoad = NO;
    
    self.oldY = scrollView.contentOffset.y;
}

#pragma mark - ----------------------具体实现----------------------
- (void)dealloc {
    [self removeObserver:self forKeyPath:@"selectedIndex"];
}

#pragma mark - 布局
- (void)didMoveToSuperview {
    self.isShowIndicator = NO;
    //获取标题组
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(sectionIndexTitles)]) {
        self.indexItems = [self.dataSource sectionIndexTitles];
        if (self.indexItems.count == 0) {
            return;
        }
    }
    else {
        return;
    }
    [self addObserver:self forKeyPath:@"selectedIndex" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    //初始化属性设置
    [self attributeSettings];
    //初始化title
    [self initialiseAllTitles];
}

#pragma mark - 外部传入当前选中组
- (void)setSelectionIndex:(NSInteger)index {
    if (index >= 0 && index <= self.indexItems.count) {
        //改变组下标
        self.isCallback = NO;
        self.selectedIndex = index;
    }
}

#pragma mark - KVO监听当前选中下标
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    //下标
    NSInteger newIndex = [[change objectForKey:@"new"] integerValue];
    NSInteger oldIndex = [[change objectForKey:@"old"] integerValue];
    //处理新旧item
    if (oldIndex >=0 && oldIndex < self.itemsViewArray.count) {
        UILabel *oldItemLabel = self.itemsViewArray[oldIndex];
        oldItemLabel.textColor = self.titleColor;
    }
    if (newIndex >= 0 && newIndex < self.itemsViewArray.count) {
        UILabel *newItemLabel = self.itemsViewArray[newIndex];
        newItemLabel.textColor = [UIColor whiteColor];
        //处理选中圆形
        //圆直径
        CGFloat diameter = ((self.itemMaxSize.width > self.itemMaxSize.height) ? self.itemMaxSize.width:self.itemMaxSize.height) + self.titleSpace;
        self.selectedImageView.frame = CGRectMake(0, 0, diameter, diameter);
        self.selectedImageView.center = newItemLabel.center;
        self.selectedImageView.layer.mask = [self imageMaskLayer:self.selectedImageView.bounds radiu:diameter/2.0];
        [self insertSubview:self.selectedImageView belowSubview:newItemLabel];
        //回调代理方法
        if (self.isCallback && self.delegate && [self.delegate respondsToSelector:@selector(selectedSectionIndexTitle:atIndex:)]) {
            [self.delegate selectedSectionIndexTitle:self.indexItems[newIndex] atIndex:newIndex];
            
            //只有手势滑动，才会触发指示器视图
            if (!self.indicatorView) {
                self.indicatorView = [[SectionIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            }
            self.indicatorView.alpha = 1.0f;
            [self.indicatorView setOrigin:CGPointMake(SCREEN_WIDTH - self.marginRight - self.titleFontSize - 10 - self.indicatorMarginRight, newItemLabel.center.y + self.frame.origin.y) title:newItemLabel.text];
            //将指示器视图添加到scrollView的父视图上
            if (self.delegate && [self.delegate respondsToSelector:@selector(addIndicatorView:)]) {
                [self.delegate addIndicatorView:self.indicatorView];
            }
        }
        //        NSLog(@"selected title = %@", self.indexItems[newIndex]);
    }
}

#pragma mark - 初始化属性设置
- (void)attributeSettings {
    //文字大小
    if (self.titleFontSize == 0) {
        self.titleFontSize = 10;
    }
    //字体颜色
    if (!self.titleColor) {
        self.titleColor = [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.f];
    }
    //右边距
    if (self.marginRight == 0) {
        self.marginRight = 7;
    }
    //文字间距
    if (self.titleSpace == 0) {
        self.titleSpace = 4;
    }
    
    //默认就允许滚动改变组
    self.isAllowedChange = YES;
    
    self.isFirstLoad = YES;
}

#pragma mark - 初始化title
- (void)initialiseAllTitles {
    //高度是否符合
    CGFloat totalHeight = (self.indexItems.count * self.titleFontSize) + ((self.indexItems.count + 1) * self.titleSpace);
    if (CGRectGetHeight(self.frame) < totalHeight) {
        NSLog(@"View height is not enough");
        return;
    }
    //宽度是否符合
    CGFloat totalWidth = self.titleFontSize + self.marginRight;
    if (CGRectGetWidth(self.frame) < totalWidth) {
        NSLog(@"View width is not enough");
        return;
    }
    //设置Y坐标最小值
    self.minY = (CGRectGetHeight(self.frame) - totalHeight)/2.0;
    CGFloat startY = self.minY  + self.titleSpace;
    //以 'W' 字母为标准作为其他字母的标准宽高
    self.itemMaxSize = [@"W" boundingRectWithSize:CGSizeMake(SCREEN_WIDTH, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:self.titleFontSize]} context:nil].size;
    //标题视图布局
    for (int i=0; i<self.indexItems.count; i++) {
        NSString *title = self.indexItems[i];
        UILabel *itemLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame) - self.marginRight - self.titleFontSize, startY, self.itemMaxSize.width, self.itemMaxSize.height)];
        itemLabel.font = [UIFont boldSystemFontOfSize:self.titleFontSize];
        itemLabel.textColor = self.titleColor;
        itemLabel.text = title;
        itemLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.itemsViewArray addObject:itemLabel];
        [self addSubview:itemLabel];
        //重新计算start Y
        startY = startY + self.itemMaxSize.height + self.titleSpace;
    }
    //设置Y坐标最大值
    self.maxY = startY;
}

#pragma mark - 事件处理
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint location = [touch locationInView:self];
    //滑动期间不允许scrollview改变组
    self.isAllowedChange = NO;
    [self selectedIndexByPoint:location];
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint location = [touch locationInView:self];
    [self selectedIndexByPoint:location];
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint location = [touch locationInView:self];
    
    if (location.y < self.minY || location.y > self.maxY) {
        return;
    }
    
    [self selectedIndexByPoint:location];
    
    //如果当前有动画正在进行，则停止当前动画，再开始新动画，否则，直接开始新动画
    if ([self.indicatorView.layer animationForKey:@"basic"]) {
        [self.indicatorView.layer removeAnimationForKey:@"basic"];
        self.isAnimating = YES;
    }
    else {
        [self animationView:self.indicatorView];
    }
    //滑动结束后，允许scrollview改变组
    self.isAllowedChange = YES;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [self animationView:self.indicatorView];
    //滑动结束后，允许scrollview改变组
    self.isAllowedChange = YES;
}

- (void)animationView:(UIView *)view {
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath = @"opacity";
    animation.duration = 0.3;
    animation.fromValue = @1;
    animation.toValue = @0;
    animation.repeatCount = 1;
    animation.delegate = self;
    animation.removedOnCompletion = NO;
    animation.fillMode = @"forwards";
    
    //即将开始进行动画前，判断指示器视图是否已经添加到父视图上
    if (!self.indicatorView.superview) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(addIndicatorView:)]) {
            [self.delegate addIndicatorView:self.indicatorView];
        }
    }
    //当前动画可以被结束
    self.isAnimating = NO;
    [view.layer addAnimation:animation forKey:@"basic"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    //self.isAnimating = YES，表示需要停止当前动画，开始新的动画，NO表示结束当前动画
    if (self.isAnimating) {
        [self animationView:self.indicatorView];
    }
    else {
        [self.indicatorView removeFromSuperview];
        [self.indicatorView.layer removeAllAnimations];
    }
}

#pragma mark - 根据Y坐标计算选中位置，当坐标有效时，返回YES
- (void)selectedIndexByPoint:(CGPoint)location {
    if (location.y >= self.minY && location.y <= self.maxY) {
        //计算下标
        NSInteger offsetY = location.y - self.minY - (self.titleSpace / 2.0);
        //单位高
        CGFloat item = self.itemMaxSize.height + self.titleSpace;
        //计算当前下标
        NSInteger index = (offsetY / item) ;//+ ((offsetY % item == 0)?0:1) - 1;
        if (index != self.selectedIndex && index < self.indexItems.count && index >= 0) {
            self.isCallback = YES;
            self.selectedIndex = index;
        }
    }
}

#pragma mark - getter
- (NSMutableArray *)itemsViewArray {
    if (!_itemsViewArray) {
        _itemsViewArray = [NSMutableArray array];
    }
    return _itemsViewArray;
}

- (UIImageView *)selectedImageView {
    if (!_selectedImageView) {
        _selectedImageView = [[UIImageView alloc] init];
        _selectedImageView.backgroundColor = [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.f];
    }
    return _selectedImageView;
}


- (CAShapeLayer *)imageMaskLayer:(CGRect)bounds radiu:(CGFloat)radiu {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radiu, radiu)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    return maskLayer;
}

@end
