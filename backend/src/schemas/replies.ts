import { Type } from '@sinclair/typebox';

export const ErrorResponseSchema = Type.Object({
  error: Type.String(),
});

export const UnauthorizedResponseSchema = Type.Object({
  error: Type.String(),
});
