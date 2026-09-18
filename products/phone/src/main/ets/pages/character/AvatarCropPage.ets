import { image } from '@kit.ImageKit';
import { promptAction } from '@kit.ArkUI';
import { RouterUtils } from 'lib_common';
import { NavHeaderBar } from 'lib_widget';
import { AvatarCropSession, AvatarService } from '../../common/AvatarService';

const CROP_SIZE: number = 300;
const MAX_ZOOM: number = 4;

@Builder
export function AvatarCropPageBuilder() {
  AvatarCropPage()
}

@ComponentV2
struct AvatarCropPage {
  @Local preview?: image.PixelMap;
  @Local sourceWidth: number = 1;
  @Local sourceHeight: number = 1;
  @Local zoom: number = 1;
  @Local offsetX: number = 0;
  @Local offsetY: number = 0;
  @Local isLoading: boolean = true;
  @Local isSaving: boolean = false;
  private panStartX: number = 0;
  private panStartY: number = 0;
  private pinchStartZoom: number = 1;

  aboutToAppear(): void {
    this.loadPreview();
  }

  aboutToDisappear(): void {
    this.preview?.release();
    this.preview = undefined;
    AvatarCropSession.clear();
  }

  build() {
    NavDestination() {
      Column() {
        NavHeaderBar({ title: '裁切头像' })

        if (this.isLoading) {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(40)
              .height(40)
            Text('正在读取图片…')
              .fontColor($r('sys.color.font_secondary'))
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.preview) {
          Column({ space: 20 }) {
            Text('拖动调整位置，双指或滑杆缩放')
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_secondary'))

            Stack({ alignContent: Alignment.Center }) {
              Image(this.preview)
                .width(this.baseDisplayWidth())
                .height(this.baseDisplayHeight())
                .objectFit(ImageFit.Fill)
                .scale({ x: this.zoom, y: this.zoom })
                .translate({ x: this.offsetX, y: this.offsetY })
            }
            .width(CROP_SIZE)
            .height(CROP_SIZE)
            .clip(true)
            .borderRadius(CROP_SIZE / 2)
            .border({ width: 3, color: $r('sys.color.icon_emphasize') })
            .backgroundColor(Color.Black)
            .gesture(
              GestureGroup(GestureMode.Parallel,
                PanGesture()
                  .onActionStart(() => {
                    this.panStartX = this.offsetX;
                    this.panStartY = this.offsetY;
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    this.offsetX = this.panStartX + event.offsetX;
                    this.offsetY = this.panStartY + event.offsetY;
                    this.clampOffsets();
                  }),
                PinchGesture({ fingers: 2 })
                  .onActionStart(() => {
                    this.pinchStartZoom = this.zoom;
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    this.zoom = Math.max(1, Math.min(MAX_ZOOM, this.pinchStartZoom * event.scale));
                    this.clampOffsets();
                  })
              )
            )

            Row({ space: 12 }) {
              SymbolGlyph($r('sys.symbol.minus'))
                .fontSize($r('sys.float.Body_L'))
              Slider({ value: this.zoom, min: 1, max: MAX_ZOOM, step: 0.01 })
                .layoutWeight(1)
                .onChange((value: number) => {
                  this.zoom = value;
                  this.clampOffsets();
                })
              SymbolGlyph($r('sys.symbol.plus'))
                .fontSize($r('sys.float.Body_L'))
            }
            .width('100%')

            Row({ space: 12 }) {
              Button('重置')
                .layoutWeight(1)
                .height(44)
                .fontColor($r('sys.color.font_primary'))
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onClick(() => {
                  this.zoom = 1;
                  this.offsetX = 0;
                  this.offsetY = 0;
                })
              Button(this.isSaving ? '正在保存…' : '使用头像')
                .layoutWeight(1)
                .height(44)
                .enabled(!this.isSaving)
                .onClick(() => {
                  this.saveCrop();
                })
            }
            .width('100%')
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ left: 24, right: 24, bottom: 32 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.background_primary'))
    }
    .hideTitleBar(true)
  }

  private async loadPreview(): Promise<void> {
    const sourceUri = AvatarCropSession.getSourceUri();
    if (!sourceUri) {
      promptAction.showToast({ message: '没有可裁切的图片' });
      RouterUtils.pop();
      return;
    }
    try {
      const size = await AvatarService.getImageSize(sourceUri);
      this.sourceWidth = size.width;
      this.sourceHeight = size.height;
      this.preview = await AvatarService.createPreview(sourceUri);
    } catch (_) {
      promptAction.showToast({ message: '无法读取所选图片' });
      RouterUtils.pop();
    } finally {
      this.isLoading = false;
    }
  }

  private saveCrop(): void {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    AvatarService.cropAndSave(AvatarCropSession.getSourceUri(), AvatarCropSession.getCharacterId(),
      this.sourceWidth, this.sourceHeight, this.zoom, this.offsetX, this.offsetY, CROP_SIZE)
      .then((avatarUri: string) => {
        RouterUtils.pop(avatarUri);
      })
      .catch(() => {
        promptAction.showToast({ message: '头像裁切保存失败' });
        this.isSaving = false;
      });
  }

  private baseDisplayWidth(): number {
    return CROP_SIZE * this.sourceWidth / Math.min(this.sourceWidth, this.sourceHeight);
  }

  private baseDisplayHeight(): number {
    return CROP_SIZE * this.sourceHeight / Math.min(this.sourceWidth, this.sourceHeight);
  }

  private clampOffsets(): void {
    const maxX = Math.max(0, (this.baseDisplayWidth() * this.zoom - CROP_SIZE) / 2);
    const maxY = Math.max(0, (this.baseDisplayHeight() * this.zoom - CROP_SIZE) / 2);
    this.offsetX = Math.max(-maxX, Math.min(maxX, this.offsetX));
    this.offsetY = Math.max(-maxY, Math.min(maxY, this.offsetY));
  }
}
