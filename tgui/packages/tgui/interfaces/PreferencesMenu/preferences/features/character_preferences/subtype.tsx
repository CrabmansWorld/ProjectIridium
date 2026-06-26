// IRIDIUM MODULE

import type { FeatureChoiced } from '../base';
import { FeatureDropdownInput } from '../dropdowns';

export const subtype: FeatureChoiced = {
  name: 'Subspecies',
  description:
    'Make sure to read Roleplay Standards & Lore for additional subspecies restrictions.',
  component: FeatureDropdownInput,
};
