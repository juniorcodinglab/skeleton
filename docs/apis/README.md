# APIs externas

Um arquivo por provedor (`<provedor>.md`), gerado pela skill `requisitos`. É a fonte de verdade do agente para autenticação, endpoints e formato de resposta, e os fixtures de teste seguem os exemplos daqui.

Modelo:

~~~markdown
# <Provedor>

- Documentação oficial: <link>
- Autenticação: <tipo, variáveis de ambiente usadas>
- Limites de taxa: <...>

## <Endpoint usado>
`METHOD /caminho`

Request:
```json
{}
```

Response (exemplo real):
```json
{}
```

Erros comuns: <código → significado>
~~~

Marque com `> Não verificado` qualquer formato presumido.
