// IRIDIUM MODULE

import type {
  FeatureChoiced,
  FeatureChoicedServerData,
  FeatureValueProps,
} from '../base';
import { FeatureDropdownInput } from '../dropdowns';

export const subtype: FeatureChoiced = {
  name: 'Subspecies',
  component: (
    props: FeatureValueProps<string, string, FeatureChoicedServerData>,
  ) => <FeatureDropdownInput buttons {...props} />,
};
