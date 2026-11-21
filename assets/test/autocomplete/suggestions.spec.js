import {getSuggestions} from '../../js/autocomplete/suggestions'
describe('getSuggestions', () => {
  before(() => {
    window.sidebarNodes = {
      exceptions: [{
        id: 'Мое исключение',
        title: 'Мое исключение'
      }],
      modules: [
        {
          id: 'Map',
          title: 'Map',
          nodeGroups: [
            {key: 'functions', nodes: [{id: 'fetch/2', anchor: 'fetch/2'}]}
          ]
        },
        {
          id: 'Kernel',
          title: 'Kernel',
          nodeGroups: [
            {
              key: 'functions',
              nodes: [
                {id: '@/1', anchor: '@/1'},
                {id: '&&/2', anchor: '&&/2'},
                {id: '<>/2', anchor: '<>/2'},
                {id: 'совпадение?/1', anchor: 'совпадение?/1'}
              ]
            }
          ]
        },
        {
          id: 'Ecto.Repo',
          title: 'Ecto.Repo',
          nodeGroups: [
            {
              key: 'callbacks',
              nodes: [
                {id: 'get_by/3', anchor: 'c:get_by/3'},
                {id: 'insert/2', anchor: 'c:insert/2'},
                {id: 'insert_all/3', anchor: 'c:insert_all/3'}
              ]
            }
          ]
        },
        {
          id: 'Ecto.Schema',
          title: 'Ecto.Schema',
          nodeGroups: [
            {key: 'types', nodes: [{ id: 'has_many/1', anchor: 't:has_many/1' }]}
          ]
        }
      ],
      tasks: [{id: 'phx.server', title: 'phx.server'}],
      extras: [{id: 'api-reference', title: 'Справочник по API'}]
    }
  })
  describe('find', () => {
    it('возвращает соответствующие модули, задачи и исключения', () => {
      expect(getSuggestions('Map').length).to.eql(1)
      expect(getSuggestions('Ecto.Repo').length).to.eql(1)
      expect(getSuggestions('phx.server').length).to.eql(1)
    })
    it('возвращает соответствующие функции, обратные вызовы и типы', () => {
      expect(getSuggestions('get_by').length).to.eql(1)
      expect(getSuggestions('fetch').length).to.eql(1)
      expect(getSuggestions('has_many').length).to.eql(1)
    })
    it('игнорирует соответствующие дополнения', () => {
      expect(getSuggestions('api-reference').length).to.eql(0)
    })
    it('обрабатывает специальные символы', () => {
      expect(getSuggestions('&&/2').length).to.eql(1)
      expect(getSuggestions('<>').length).to.eql(1)
      expect(getSuggestions('@').length).to.eql(1)
      expect(getSuggestions('соответствовать?').length).to.eql(1)
    })
    it('не чувствителен к регистру', () => {
      expect(getSuggestions('Мое ИСКЛЮЧЕНИЕ')).to.eql(getSuggestions('мое исключение'))
    })
    it('возвращает максимум 5 результатов', () => {
      expect(getSuggestions('e').length).to.eql(5)
    })
    it('не возвращает результатов, если совпадение не найдено', () => {
      expect(getSuggestions('не существует')).to.eql([])
    })
    it('не возвращает результатов, если не указан поисковый запрос', () => {
      expect(getSuggestions()).to.eql([])
    })
    it('не возвращает результатов, если поисковый запрос состоит из символов пробелов', () => {
      const searchTerm = '  '
      expect(getSuggestions(searchTerm)).to.eql([])
    })
    it('выделяет совпавший фрагмент', () => {
      expect(getSuggestions('get')[0].title).to.eql('<em>get</em>_by/3')
      expect(getSuggestions('Repo.get_')[0].title).to.eql('<em>get_</em>by/3')
      expect(getSuggestions('Ecto.Repo.get_by')[0].title).to.eql('<em>get_by</em>/3')
      expect(getSuggestions('po.get_by')[0].title).to.eql('<em>get_by</em>/3')
    })
    it('сортирует результаты, помещая более близкие совпадения вверху', () => {
      let results = getSuggestions('insert')
      expect(results[0].title).to.eql('<em>insert</em>/2')
      expect(results[1].title).to.eql('<em>insert</em>_all/3')
    })
    it('помечает обратные вызовы специальной меткой', () => {
      const firstResult = getSuggestions('get_by')[0]
      expect(firstResult.label).to.eql('callback')
    })
    it('маркирует типы специальной меткой', () => {
      const firstResult = getSuggestions('has_many')[0]
      expect(firstResult.label).to.eql('type')
    })
    it('генерирует ссылку для каждого предложения', () => {
      expect(getSuggestions('has_many')[0].link).to.eql('Ecto.Schema.html#t:has_many/1')
      expect(getSuggestions('map')[0].link).to.eql('Map.html')
      expect(getSuggestions('fetch')[0].link).to.eql('Map.html#fetch/2')
    })
  })
})