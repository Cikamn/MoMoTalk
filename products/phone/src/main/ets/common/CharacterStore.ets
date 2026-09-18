import { PreferenceUtils } from 'lib_common';
import { AIConfigStore, DEFAULT_ROLE_PROMPT } from './AIConfig';

export const CHARACTER_CHANGED: string = 'character_changed';
export const OPEN_CHARACTER_CHAT: string = 'open_character_chat';
export const ARONA_DEFAULT_DESCRIPTION: string = '什亭之匣的系统管理员，陪伴老师处理日常事务。';

const CHARACTER_FILE: string = 'character_profiles';
const CHARACTER_LIST_KEY: string = 'profiles';
const ACTIVE_CHARACTER_KEY: string = 'active_character_id';

export class CharacterProfile {
  id: string = '';
  displayName: string = '';
  description: string = '';
  systemPrompt: string = '';
  loreEnabled: boolean = false;
  knowledgeBaseFile: string = '';
  builtIn: boolean = false;
  storeId: string = '';
  avatarUri: string = '';
}

export class CharacterStore {
  public static loadAll(): CharacterProfile[] {
    const preference = PreferenceUtils.getInstance(undefined, CHARACTER_FILE);
    const value = preference.get(CHARACTER_LIST_KEY, '');
    if (typeof value === 'string' && value.length > 0) {
      try {
        const parsed: Object = JSON.parse(value) as Object;
        if (Array.isArray(parsed)) {
          const saved = parsed as CharacterProfile[];
          const profiles = saved
            .filter((item: CharacterProfile) => item !== null && typeof item === 'object')
            .map((item: CharacterProfile) => CharacterStore.normalize(item));
          if (profiles.length > 0) {
            return CharacterStore.uniqueById(profiles);
          }
        }
      } catch (_) {
      }
    }
    const profiles = [CharacterStore.createAronaProfile()];
    CharacterStore.saveAll(profiles);
    return profiles;
  }

  public static getActive(): CharacterProfile {
    const profiles = CharacterStore.loadAll();
    const activeId = PreferenceUtils.getInstance(undefined, CHARACTER_FILE).get(ACTIVE_CHARACTER_KEY, 'arona');
    const active = profiles.find((item: CharacterProfile) => item.id === activeId);
    return active ?? profiles[0];
  }

  public static setActive(id: string): void {
    if (!CharacterStore.loadAll().some((item: CharacterProfile) => item.id === id)) {
      return;
    }
    PreferenceUtils.getInstance(undefined, CHARACTER_FILE).put(ACTIVE_CHARACTER_KEY, id);
  }

  public static getById(id: string): CharacterProfile | undefined {
    return CharacterStore.loadAll().find((item: CharacterProfile) => item.id === id);
  }

  public static save(profile: CharacterProfile): void {
    const profiles = CharacterStore.loadAll();
    const normalized = CharacterStore.normalize(profile);
    const index = profiles.findIndex((item: CharacterProfile) => item.id === normalized.id);
    if (index >= 0) {
      profiles[index] = normalized;
    } else {
      profiles.push(normalized);
    }
    CharacterStore.saveAll(profiles);
  }

  public static delete(id: string): CharacterProfile | undefined {
    const profiles = CharacterStore.loadAll();
    const removed = profiles.find((item: CharacterProfile) => item.id === id);
    if (!removed || removed.builtIn) {
      return undefined;
    }
    let remaining = profiles.filter((item: CharacterProfile) => item.id !== id);
    if (remaining.length === 0) {
      remaining = [CharacterStore.createAronaProfile()];
    }
    CharacterStore.saveAll(remaining);
    const preference = PreferenceUtils.getInstance(undefined, CHARACTER_FILE);
    if (preference.get(ACTIVE_CHARACTER_KEY, 'arona') === id) {
      const fallback = remaining.find((item: CharacterProfile) => item.id === 'arona') ?? remaining[0];
      preference.put(ACTIVE_CHARACTER_KEY, fallback.id);
    }
    return removed;
  }

  public static createCustom(): CharacterProfile {
    const profile = new CharacterProfile();
    profile.id = `custom_${Date.now()}`;
    profile.displayName = '新角色';
    profile.description = '一位等待完善设定的新角色';
    profile.systemPrompt = '请在这里描述角色身份、称呼方式、性格、语气和回答边界。';
    profile.loreEnabled = false;
    profile.knowledgeBaseFile = '';
    profile.builtIn = false;
    profile.storeId = `Chat_${profile.id}`;
    return profile;
  }

  private static createAronaProfile(): CharacterProfile {
    const oldConfig = AIConfigStore.load();
    const profile = new CharacterProfile();
    profile.id = 'arona';
    profile.displayName = oldConfig.assistantName || '阿罗娜';
    profile.description = ARONA_DEFAULT_DESCRIPTION;
    profile.systemPrompt = oldConfig.systemPrompt || DEFAULT_ROLE_PROMPT;
    profile.loreEnabled = true;
    profile.knowledgeBaseFile = 'lore/arona_lore_v1.json';
    profile.builtIn = true;
    profile.storeId = 'Chat';
    return profile;
  }

  private static saveAll(profiles: CharacterProfile[]): void {
    PreferenceUtils.getInstance(undefined, CHARACTER_FILE).put(CHARACTER_LIST_KEY, JSON.stringify(profiles));
  }

  private static normalize(profile: CharacterProfile): CharacterProfile {
    const normalized = new CharacterProfile();
    const id = typeof profile.id === 'string' ? profile.id.trim() : '';
    const displayName = typeof profile.displayName === 'string' ? profile.displayName.trim() : '';
    const description = typeof profile.description === 'string' ? profile.description.trim() : '';
    const systemPrompt = typeof profile.systemPrompt === 'string' ? profile.systemPrompt.trim() : '';
    const knowledgeBaseFile = typeof profile.knowledgeBaseFile === 'string' ? profile.knowledgeBaseFile : '';
    const storeId = typeof profile.storeId === 'string' ? profile.storeId : '';
    const avatarUri = typeof profile.avatarUri === 'string' ? profile.avatarUri : '';
    normalized.id = id || `custom_${Date.now()}`;
    normalized.displayName = displayName || '未命名角色';
    normalized.description = description || (normalized.id === 'arona' ? ARONA_DEFAULT_DESCRIPTION :
      '使用自定义角色提示词');
    normalized.systemPrompt = systemPrompt || '请以当前角色身份自然回答用户。';
    normalized.knowledgeBaseFile = normalized.id === 'arona' ?
      (knowledgeBaseFile || 'lore/arona_lore_v1.json') : knowledgeBaseFile;
    normalized.loreEnabled = normalized.id === 'arona' ? profile.loreEnabled !== false :
      profile.loreEnabled === true && normalized.knowledgeBaseFile.length > 0;
    normalized.builtIn = normalized.id === 'arona' || profile.builtIn === true;
    normalized.storeId = storeId || `Chat_${normalized.id}`;
    normalized.avatarUri = avatarUri;
    return normalized;
  }

  private static uniqueById(profiles: CharacterProfile[]): CharacterProfile[] {
    const ids: Set<string> = new Set();
    return profiles.filter((profile: CharacterProfile) => {
      if (ids.has(profile.id)) {
        return false;
      }
      ids.add(profile.id);
      return true;
    });
  }
}
