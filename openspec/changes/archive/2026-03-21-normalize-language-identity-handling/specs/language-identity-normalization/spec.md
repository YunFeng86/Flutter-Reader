## ADDED Requirements

### Requirement: Equivalent language tags SHALL normalize to one business identity
The system SHALL convert user-configured target language tags, follow-system locale tags, persisted reminder suppression tags, and runtime language inputs into a canonical business identity before they are compared or displayed.

#### Scenario: Simplified Chinese variants collapse to one identity
- **WHEN** the system receives `zh`, `zh-CN`, `zh-SG`, `zh-Hans`, or `zh-Hans-CN` as a target or runtime language tag
- **THEN** it SHALL treat those values as the same canonical language identity for comparison, display, and translation targeting

#### Scenario: Traditional Chinese variants collapse to one identity
- **WHEN** the system receives `zh-TW`, `zh-HK`, `zh-MO`, `zh-Hant`, or `zh-Hant-HK` as a target or runtime language tag
- **THEN** it SHALL treat those values as the same canonical language identity for comparison, display, and translation targeting

#### Scenario: Regional variants of non-Chinese target languages remain semantically equal
- **WHEN** the system receives region-specific variants such as `en-GB`, `en-US`, `ja-JP`, or `ko-KR`
- **THEN** it SHALL compare them using the canonical identity of their business language rather than treating each region tag as a distinct source or target language

### Requirement: Reader language mismatch behavior SHALL compare canonical identities
The Reader SHALL decide whether to show a language-mismatch reminder or auto-trigger translation by comparing canonical source and target identities instead of raw language tag strings.

#### Scenario: Equivalent source and target identities do not trigger a mismatch
- **WHEN** source content resolves to the same canonical identity as the target language, including cases such as `zh-Hans` versus `zh-Hans-CN` or `en` versus `en-GB`
- **THEN** the Reader SHALL NOT show a language-mismatch reminder and SHALL NOT auto-trigger translation solely because the raw tags differ

#### Scenario: Distinct canonical identities still trigger a mismatch
- **WHEN** source content resolves to a different canonical identity than the target language, including cases such as `zh-Hant` versus `zh-Hans` or `en` versus `fr`
- **THEN** the Reader SHALL show the language-mismatch reminder and SHALL remain eligible to auto-trigger translation according to existing auto-translate settings

#### Scenario: Unknown source identity suppresses mismatch behavior
- **WHEN** source content cannot be classified with sufficient confidence and resolves to `unknown`
- **THEN** the Reader SHALL NOT show a language-mismatch reminder and SHALL NOT auto-trigger translation based on language mismatch alone

### Requirement: Source language detection SHALL prefer safe, script-aware identities
The system SHALL derive source language identity through a script-aware detection pipeline that can distinguish Simplified Chinese, Traditional Chinese, supported script-heavy languages, and low-confidence content.

#### Scenario: Chinese content resolves to a script-aware identity when signal is sufficient
- **WHEN** article content contains enough Chinese-script evidence to distinguish Simplified and Traditional forms
- **THEN** source language detection SHALL resolve the content to `zh-Hans` or `zh-Hant` instead of a coarse `zh` identity

#### Scenario: Script-heavy languages remain directly identifiable
- **WHEN** article content contains strong Japanese, Korean, or Cyrillic signals
- **THEN** source language detection SHALL resolve the content to the corresponding canonical identity used by Reader comparison and translation flows

#### Scenario: Short or mixed content returns unknown
- **WHEN** article content is too short, too mixed, or too ambiguous to classify safely
- **THEN** source language detection SHALL return `unknown` rather than guessing a canonical identity

### Requirement: Language labels SHALL display canonical user-facing names
User-visible language labels in Reader reminders and translation settings SHALL display stable language names derived from canonical language identities instead of exposing raw locale tags.

#### Scenario: Simplified Chinese target displays a localized language name
- **WHEN** the target language is configured or inferred from any Simplified Chinese variant such as `zh-Hans-CN`
- **THEN** the UI SHALL display the localized user-facing name for Simplified Chinese instead of the raw tag string

#### Scenario: Traditional Chinese target displays a localized language name
- **WHEN** the target language is configured or inferred from any Traditional Chinese variant such as `zh-Hant-HK`
- **THEN** the UI SHALL display the localized user-facing name for Traditional Chinese instead of the raw tag string

#### Scenario: Follow-system locale is unsupported by app localizations
- **WHEN** the system locale is not one of the app's supported UI locales but still implies a target language identity for Reader AI behavior
- **THEN** the Reader SHALL fall back to a supported UI locale for localizations lookup while preserving the correct canonical target identity for comparison and translation

### Requirement: Translation providers SHALL map canonical identities to provider codes
The translation subsystem SHALL derive provider-specific target language codes from canonical target identities so that historical or region-specific input tags do not change provider behavior.

#### Scenario: Simplified Chinese requests map consistently for each provider
- **WHEN** translation is requested for a target identity equivalent to Simplified Chinese
- **THEN** each translation provider SHALL receive the provider-specific code associated with the canonical Simplified Chinese identity rather than a raw historical tag

#### Scenario: Traditional Chinese requests map consistently for each provider
- **WHEN** translation is requested for a target identity equivalent to Traditional Chinese
- **THEN** each translation provider SHALL receive the provider-specific code associated with the canonical Traditional Chinese identity rather than a raw historical tag

#### Scenario: Historical settings remain compatible
- **WHEN** a persisted settings file contains an older but semantically equivalent language tag such as `zh-CN`, `zh-Hans-CN`, or `en-GB`
- **THEN** the system SHALL preserve compatible behavior by resolving that input to the canonical target identity before Reader or translation logic consumes it
