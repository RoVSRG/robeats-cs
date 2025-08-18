import React from 'react';
import {Text, Spacer, Box} from 'ink';

type Props = {
	name: string | undefined;
};

export default function App({name = 'Stranger'}: Props) {
	return (
		<Box flexDirection="column" borderStyle="round" width="100%" height="100%">
			<Text>
				RoBeats CS CLI
			</Text>

			<Spacer />

			<Text>
				Hello, <Text bold>{name}</Text>
			</Text>
		</Box>
	);
}
