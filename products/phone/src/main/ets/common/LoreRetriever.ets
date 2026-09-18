import { util } from '@kit.ArkTS';
import { Logger } from 'lib_common';

const TAG: string = '[LoreRetriever]';
const DEFAULT_LORE_FILE: string = 'lore/arona_lore_v1.json';

interface LoreRetrievalConfig {
  maxResults: number;
  maxContextCharacters: number;
  titleMatchScore: number;
  keywordMatchScore: number;
  aliasMatchScore: number;
  factMatchScore: number;
}

interface LoreAliasGroup {
  canonical: string;
  aliases: string[];
}

interface LoreEntry {
  id: string;
  category: string;
  chapter: string;
  title: string;
  keywords: string[];
  aliases: string[];
  knowledgeScope: string;
  spoilerLevel: number;
  confidence: string;
  facts: string[];
  roleMemory: string;
  dialoguePolicy: string;
}

interface LoreKnowledgeBase {
  displayName: string;
  retrievalConfig: LoreRetrievalConfig;
  aliasGroups: LoreAliasGroup[];
  entries: LoreEntry[];
}

interface ScoredLoreEntry {
  entry: LoreEntry;
  score: number;
}

export interface LoreSearchResult {
  context: string;
  matchedIds: string[];
}

export class LoreRetriever {
  private static instance?: LoreRetriever;
  private knowledgeBases: Map<string, LoreKnowledgeBase> = new Map();

  public static getInstance(): LoreRetriever {
    if (!LoreRetriever.instance) {
      LoreRetriever.instance = new LoreRetriever();
    }
    return LoreRetriever.instance;
  }

  public getEntryCount(fileName: string = DEFAULT_LORE_FILE): number {
    return this.loadKnowledgeBase(fileName)?.entries.length ?? 0;
  }

  public search(input: string, fileName: string = DEFAULT_LORE_FILE): LoreSearchResult {
    const knowledgeBase = this.loadKnowledgeBase(fileName);
    const query = this.normalize(input);
    if (!knowledgeBase || !query) {
      return { context: '', matchedIds: [] };
    }

    const expandedTerms = this.expandAliasTerms(query, knowledgeBase.aliasGroups);
    const scored: ScoredLoreEntry[] = [];
    knowledgeBase.entries.forEach((entry: LoreEntry) => {
      if (entry.confidence === 'excluded') {
        return;
      }
      const score = this.scoreEntry(query, expandedTerms, entry, knowledgeBase.retrievalConfig);
      if (score > 0) {
        scored.push({ entry: entry, score: score });
      }
    });

    scored.sort((left: ScoredLoreEntry, right: ScoredLoreEntry) => {
      if (right.score !== left.score) {
        return right.score - left.score;
      }
      return 0;
    });

    const selected = scored.slice(0, knowledgeBase.retrievalConfig.maxResults);
    let context = '';
    const matchedIds: string[] = [];
    selected.forEach((item: ScoredLoreEntry) => {
      const block = this.formatEntry(item.entry);
      if (context.length + block.length > knowledgeBase.retrievalConfig.maxContextCharacters) {
        return;
      }
      context += block;
      matchedIds.push(item.entry.id);
    });
    return { context: context.trim(), matchedIds: matchedIds };
  }

  private loadKnowledgeBase(fileName: string): LoreKnowledgeBase | undefined {
    if (!fileName) {
      return undefined;
    }
    const cached = this.knowledgeBases.get(fileName);
    if (cached) {
      return cached;
    }
    try {
      const value = getContext().resourceManager.getRawFileContentSync(fileName);
      const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      const json = decoder.decodeToString(new Uint8Array(value.buffer), { stream: false });
      const knowledgeBase = JSON.parse(json) as LoreKnowledgeBase;
      this.knowledgeBases.set(fileName, knowledgeBase);
      Logger.info(TAG, `Loaded local lore entries: ${knowledgeBase.entries.length}`);
      return knowledgeBase;
    } catch (error) {
      Logger.error(TAG, `Failed to load local lore: ${JSON.stringify(error)}`);
    }
    return undefined;
  }

  private expandAliasTerms(query: string, groups: LoreAliasGroup[]): string[] {
    const terms: string[] = [];
    groups.forEach((group: LoreAliasGroup) => {
      const candidates = [group.canonical, ...group.aliases];
      const canonical = this.normalize(group.canonical);
      if (query.includes(canonical)) {
        return;
      } else if (group.aliases.some((alias: string) => query.includes(this.normalize(alias)))) {
        candidates.forEach((candidate: string) => {
          const normalized = this.normalize(candidate);
          if (normalized && !terms.includes(normalized)) {
            terms.push(normalized);
          }
        });
      }
    });
    return terms;
  }

  private scoreEntry(query: string, expandedTerms: string[], entry: LoreEntry,
    config: LoreRetrievalConfig): number {
    let score = 0;
    const title = this.normalize(entry.title);
    if (title && (query.includes(title) || expandedTerms.some((term: string) => title.includes(term)))) {
      score += config.titleMatchScore;
    }
    entry.keywords.forEach((keyword: string) => {
      const normalized = this.normalize(keyword);
      if (normalized && (query.includes(normalized) || expandedTerms.includes(normalized))) {
        score += this.isGenericCharacterTerm(normalized) ? 1 :
          config.keywordMatchScore + Math.min(3, Math.max(0, normalized.length - 2));
      }
    });
    entry.aliases.forEach((alias: string) => {
      const normalized = this.normalize(alias);
      if (normalized && (query.includes(normalized) || expandedTerms.includes(normalized))) {
        score += this.isGenericCharacterTerm(normalized) ? 1 : config.aliasMatchScore;
      }
    });
    entry.facts.forEach((fact: string) => {
      const normalizedFact = this.normalize(fact);
      if (expandedTerms.some((term: string) => term.length >= 2 && !this.isGenericCharacterTerm(term) &&
        normalizedFact.includes(term))) {
        score += config.factMatchScore;
      }
    });
    return score;
  }

  private formatEntry(entry: LoreEntry): string {
    return `\n[${entry.id}｜${entry.chapter}｜${entry.title}]\n` +
      `认知范围：${entry.knowledgeScope}；置信度：${entry.confidence}\n` +
      `事实：${entry.facts.join('；')}\n` +
      `角色记忆：${entry.roleMemory}\n` +
      `表达边界：${entry.dialoguePolicy}\n`;
  }

  private normalize(value: string): string {
    return value.toLowerCase().replace(/\s+/g, '');
  }

  private isGenericCharacterTerm(value: string): boolean {
    return ['阿罗娜', '阿洛娜', '彩奈', 'arona', 'アロナ'].includes(value);
  }
}
