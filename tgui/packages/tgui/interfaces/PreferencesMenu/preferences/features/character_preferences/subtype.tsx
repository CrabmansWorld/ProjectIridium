// IRIDIUM MODULE

import type {
  FeatureChoiced,
  FeatureChoicedServerData,
  FeatureValueProps,
} from '../base';
import { FeatureDropdownInput } from '../dropdowns';

export const subtype: FeatureChoiced = {
  name: 'Subspecies',
  description:
    'Make sure to read Roleplay Standards & Lore for additional subspecies restrictions.',
  component: (
    props: FeatureValueProps<string, string, FeatureChoicedServerData>,
  ) => <FeatureDropdownInput buttons {...props} />,
};
