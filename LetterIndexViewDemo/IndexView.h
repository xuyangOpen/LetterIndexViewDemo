//
//  IndexView.h
//  LetterIndexViewDemo
//
//  Created by imac on 2017/10/12.
//  Copyright © 2017年 ms. All rights reserved.
//

#import <UIKit/UIKit.h>

/** 代理方法 */
@protocol IndexViewDelegate <NSObject>

@optional
- (void)tableView:(UITableView *_Nonnull)tableView didSelectRowAtIndexPath:(NSIndexPath *_Nullable)indexPath;
- (CGFloat)tableView:(UITableView *_Nullable)tableView heightForHeaderInSection:(NSInteger)section;
- (nullable UIView *)tableView:(UITableView *_Nullable)tableView viewForHeaderInSection:(NSInteger)section;

@required
/** 当前选中下标 */
- (void)selectedSectionIndexTitle:(NSString *_Nullable)title atIndex:(NSInteger)index;
/** 添加指示器视图 */
- (void)addIndicatorView:(UIView *_Nullable)view;

@end

/** 数据源方法 */
@protocol IndexViewDataSource <NSObject>

@required
- (NSInteger)tableView:(UITableView *_Nullable)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *_Nullable)tableView:(UITableView *_Nonnull)tableView cellForRowAtIndexPath:(NSIndexPath *_Nullable)indexPath;
- (NSInteger)numberOfSectionsInTableView:(UITableView *_Nullable)tableView;

/** 组标题数组 */
- (NSArray<NSString *> *_Nullable)sectionIndexTitles;

@end

@interface IndexView : UIControl <UITableViewDelegate, UITableViewDataSource, CAAnimationDelegate>

@property (nonatomic, weak, nullable) id<IndexViewDelegate> delegate;
@property (nonatomic, weak, nullable) id<IndexViewDataSource> dataSource;

@property (nonatomic, assign) CGFloat titleFontSize;                                    /**< 字体大小 */
@property (nonatomic, strong, nullable) UIColor * titleColor;                           /**< 字体颜色 */
@property (nonatomic, assign) CGFloat marginRight;                                      /**< 右边距 */
@property (nonatomic, assign) CGFloat titleSpace;                                       /**< 文字间距 */
@property (nonatomic, assign) CGFloat indicatorMarginRight;                             /**< 指示器视图距离右侧的偏移量 */

- (void)setSelectionIndex:(NSInteger)index;                                             /** 设置当前选中组 */

@end
