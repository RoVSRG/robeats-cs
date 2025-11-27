import 'fastify';

declare module 'fastify' {
  interface FastifyReply {
    success(data?: any): FastifyReply;
    error(error: string, status?: number): FastifyReply;
  }
}