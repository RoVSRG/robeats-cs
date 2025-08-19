import { Type } from '@sinclair/typebox';

export const SuccessResponseSchema = Type.Object({
  success: Type.Boolean(),
});

export const ErrorResponseSchema = Type.Object({
  error: Type.String(),
});

export const UnauthorizedResponseSchema = Type.Object({
  success: Type.Boolean(),
  error: Type.String(),
});
