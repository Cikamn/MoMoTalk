// Arona.ets - 方案一：使用 @ComponentV2
@Builder
export function AronaChatPageBuilder() {
  AronaPage()
}

@Entry
@ComponentV2
struct AronaPage {
  @Local message: string = '阿罗娜页面已成功打开！';

  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          this.message = 'Welcome';
        })
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}