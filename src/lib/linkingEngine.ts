import { ScheduleActivity, InformalSiteUpdate } from '../types/index';

export interface ExtractedEntities {
  discipline?: 'PIPING' | 'CIVIL' | 'ELECTRICAL' | 'MECHANICAL' | 'INSTRUMENTATION' | 'HSE';
  lineOrTag?: string;
  action?: string;
  quantity?: number;
  unit?: string;
  progressPercentage?: number;
  delayReason?: string;
  materialsMentioned?: string[];
  rawText: string;
}

export interface MatchResult {
  activity: ScheduleActivity;
  confidenceScore: number;
  matchReasons: string[];
  isOutOfSequence: boolean;
  outOfSequenceWarning?: string;
}

/**
 * Intelligent Data Capture & Schedule-Linking Engine (SIH26122 Core)
 * Analyzes unstructured field inputs (Hindi, English, Hinglish, WhatsApp text, DPR logs)
 * and maps them directly to L5/L6 Schedule Activity codes with confidence metrics.
 */
export function extractEntitiesFromFieldText(text: string): ExtractedEntities {
  const lower = text.toLowerCase();
  
  // 1. Identify Discipline
  let discipline: ExtractedEntities['discipline'] = undefined;
  if (/pipe|line\s*\d+|welding|joint|spool|flange|fitting|trench lower|stringing/i.test(lower)) {
    discipline = 'PIPING';
  } else if (/pier|rebar|concrete|pour|shuttering|cube|excavat|shoring|foundation/i.test(lower)) {
    discipline = 'CIVIL';
  } else if (/cable|substation|cathodic|iccp|transformer|earthing/i.test(lower)) {
    discipline = 'ELECTRICAL';
  } else if (/scada|plc|sensor|transmitter|flowmeter|metering/i.test(lower)) {
    discipline = 'INSTRUMENTATION';
  } else if (/safety|permit|incident|toolbox|hazard|ppe/i.test(lower)) {
    discipline = 'HSE';
  }

  // 2. Identify Line or Tag
  let lineOrTag: string | undefined = undefined;
  const lineMatch = text.match(/(?:line|pipeline|pier|tag|wbs|zone|chainage)\s*([a-zA-Z0-9_\-\+]+(?:\s*\d+)?)/i);
  if (lineMatch) {
    lineOrTag = lineMatch[0];
  } else if (/line\s*24/i.test(lower)) {
    lineOrTag = 'Line 24';
  } else if (/pier\s*24/i.test(lower)) {
    lineOrTag = 'Pier 24';
  }

  // 3. Extract Progress Percentage
  let progressPercentage: number | undefined = undefined;
  const pctMatch = text.match(/(\d+(?:\.\d+)?)\s*(?:%|percent|pratisat|pratishat)/i);
  if (pctMatch) {
    progressPercentage = parseFloat(pctMatch[1]);
  }

  // 4. Extract Physical Quantity & Unit
  let quantity: number | undefined = undefined;
  let unit: string | undefined = undefined;
  const qtyMatch = text.match(/(\d+(?:\.\d+)?)\s*(meter|mtr|m|joints?|spools?|cu\.?m|cubic meter|mt|tonnes?)/i);
  if (qtyMatch) {
    quantity = parseFloat(qtyMatch[1]);
    unit = qtyMatch[2].toLowerCase();
  }

  // 5. Extract Delays / Reasons
  let delayReason: string | undefined = undefined;
  if (/delay|late|missing|shortage|ruk gaya|pending|problem|issue|ruka|rain|baarish|barish/i.test(lower)) {
    if (/material|spool|pipe|elbow|flange/i.test(lower)) {
      delayReason = 'Material / Spool delivery pending from store';
    } else if (/equipment|crane|generator|breakdown/i.test(lower)) {
      delayReason = 'Equipment downtime / breakdown';
    } else if (/rain|baarish|weather/i.test(lower)) {
      delayReason = 'Adverse weather / rain delay';
    } else {
      delayReason = 'Site execution bottleneck reported';
    }
  }

  // 6. Action Detection
  let action: string | undefined = undefined;
  if (/start|shuru|commence|began/i.test(lower)) {
    action = 'Activity Started';
  } else if (/welding|weld|welded/i.test(lower)) {
    action = 'Pipe Welding';
  } else if (/pour|pouring|dhalai/i.test(lower)) {
    action = 'Concrete Pouring';
  } else if (/inspect|inspection|check/i.test(lower)) {
    action = 'Quality Inspection';
  }

  return {
    discipline,
    lineOrTag,
    action,
    quantity,
    unit,
    progressPercentage,
    delayReason,
    rawText: text,
  };
}

/**
 * Intelligent Activity Matcher: Scores candidate L5/L6 Schedule Activities against extracted entities.
 */
export function matchEntitiesToActivities(
  entities: ExtractedEntities, 
  activities: ScheduleActivity[]
): MatchResult[] {
  const results: MatchResult[] = [];

  for (const act of activities) {
    let score = 0;
    const reasons: string[] = [];

    // Tag / Line Exact or Fuzzy Match
    if (entities.lineOrTag) {
      const tagLower = entities.lineOrTag.toLowerCase();
      if (act.name.toLowerCase().includes(tagLower) || act.description.toLowerCase().includes(tagLower) || act.activityCode.toLowerCase().includes(tagLower)) {
        score += 0.45;
        reasons.push(`Matched Tag "${entities.lineOrTag}" in activity title/scope`);
      }
    }

    // Discipline Match
    if (entities.discipline && act.discipline === entities.discipline) {
      score += 0.30;
      reasons.push(`Discipline match: ${entities.discipline}`);
    }

    // Keyword & Action Match
    const actText = (act.name + ' ' + act.description).toLowerCase();
    if (entities.action && actText.includes(entities.action.toLowerCase())) {
      score += 0.15;
      reasons.push(`Action keyword match: "${entities.action}"`);
    }

    // In-progress boost
    if (act.plannedProgress > 0 && act.plannedProgress < 100) {
      score += 0.10;
      reasons.push('Active work package in current look-ahead window');
    }

    // Cap score at 0.99
    score = Math.min(score, 0.99);

    if (score >= 0.40) {
      // Check P6-style Out-Of-Sequence
      let isOutOfSequence = false;
      let warning: string | undefined = undefined;

      // Check if predecessors are completed
      if (act.predecessorCodes && act.predecessorCodes.length > 0) {
        for (const predCode of act.predecessorCodes) {
          const pred = activities.find(a => a.activityCode === predCode);
          if (pred && pred.validatedConsensusProgress < 100) {
            isOutOfSequence = true;
            warning = `Predecessor [${pred.activityCode}] is only ${pred.validatedConsensusProgress}% complete! Starting out-of-sequence requires Engineer variance approval.`;
            break;
          }
        }
      }

      results.push({
        activity: act,
        confidenceScore: Math.round(score * 100) / 100,
        matchReasons: reasons,
        isOutOfSequence,
        outOfSequenceWarning: warning,
      });
    }
  }

  // Sort descending by confidence score
  return results.sort((a, b) => b.confidenceScore - a.confidenceScore);
}
