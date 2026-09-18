import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

export class AvatarCropSession {
  private static sourceUri: string = '';
  private static characterId: string = '';

  public static begin(sourceUri: string, characterId: string): void {
    AvatarCropSession.sourceUri = sourceUri;
    AvatarCropSession.characterId = characterId;
  }

  public static getSourceUri(): string {
    return AvatarCropSession.sourceUri;
  }

  public static getCharacterId(): string {
    return AvatarCropSession.characterId;
  }

  public static clear(): void {
    AvatarCropSession.sourceUri = '';
    AvatarCropSession.characterId = '';
  }
}

export class AvatarService {
  public static async selectImage(): Promise<string> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    const picker = new photoAccessHelper.PhotoViewPicker();
    const result = await picker.select(options);
    return result.photoUris.length > 0 ? result.photoUris[0] : '';
  }

  public static async createPreview(sourceUri: string): Promise<image.PixelMap> {
    const source = image.createImageSource(sourceUri);
    try {
      const info = await source.getImageInfo();
      const maxSide = Math.max(info.size.width, info.size.height);
      const ratio = maxSide > 1600 ? 1600 / maxSide : 1;
      return await source.createPixelMap({
        desiredSize: {
          width: Math.max(1, Math.round(info.size.width * ratio)),
          height: Math.max(1, Math.round(info.size.height * ratio))
        }
      });
    } finally {
      await source.release();
    }
  }

  public static async getImageSize(sourceUri: string): Promise<image.Size> {
    const source = image.createImageSource(sourceUri);
    try {
      const info = await source.getImageInfo();
      return info.size;
    } finally {
      await source.release();
    }
  }

  public static async cropAndSave(sourceUri: string, characterId: string, sourceWidth: number,
    sourceHeight: number, zoom: number, offsetX: number, offsetY: number, cropSize: number): Promise<string> {
    const shortestSide = Math.min(sourceWidth, sourceHeight);
    const sourceSpan = shortestSide / Math.max(1, zoom);
    const displayScale = cropSize / shortestSide * Math.max(1, zoom);
    const centerX = sourceWidth / 2 - offsetX / displayScale;
    const centerY = sourceHeight / 2 - offsetY / displayScale;
    const left = Math.max(0, Math.min(sourceWidth - sourceSpan, centerX - sourceSpan / 2));
    const top = Math.max(0, Math.min(sourceHeight - sourceSpan, centerY - sourceSpan / 2));
    const region: image.Region = {
      x: Math.round(left),
      y: Math.round(top),
      size: {
        width: Math.max(1, Math.round(sourceSpan)),
        height: Math.max(1, Math.round(sourceSpan))
      }
    };

    const source = image.createImageSource(sourceUri);
    let pixelMap: image.PixelMap | undefined;
    let outputFile: fileIo.File | undefined;
    const packer = image.createImagePacker();
    try {
      pixelMap = await source.createPixelMap({
        desiredRegion: region,
        desiredSize: { width: 512, height: 512 },
        cropAndScaleStrategy: image.CropAndScaleStrategy.CROP_FIRST
      });
      const safeId = characterId.replace(/[^a-zA-Z0-9_-]/g, '_');
      const path = `${getContext().filesDir}/avatar_${safeId}_${Date.now()}.png`;
      outputFile = fileIo.openSync(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);
      await packer.packToFile(pixelMap, outputFile.fd, { format: 'image/png', quality: 100 });
      return `file://${path}`;
    } finally {
      if (outputFile) {
        fileIo.closeSync(outputFile);
      }
      if (pixelMap) {
        await pixelMap.release();
      }
      await packer.release();
      await source.release();
    }
  }

  public static removeAvatar(uri: string): void {
    if (!uri.startsWith('file://')) {
      return;
    }
    const path = uri.slice('file://'.length);
    const filesDir = getContext().filesDir;
    if (!path.startsWith(`${filesDir}/avatar_`)) {
      return;
    }
    try {
      fileIo.unlinkSync(path);
    } catch (_) {
    }
  }
}
