  async _getApplicationSolutions(app, user) {
    let list = [];

    const Solution = mongoose.model('Solution');
    const query = { $and: [] };
    query.$and.push({ _id: { $in: app.selected } });
    if (!user) {
      query.$and.push({
        $or: [{ isPublic: true }],
      });
    }
    if (user && !isAdmin(user) && !isApprover(user)) {
      query.$and.push({
        $or: [{ owner: user.id.toString() }, { isPublic: true }],
      });
    }
    list = await Solution.find(query, {
      body: 1,
      descDimensions: 1,
      descFurther: 1,
      descMaterials: 1,
      descSteps: 1,
      files: 1,
      key: 1,
      teaser: 1,
      title: 1,
    });
    return list.map((item) => item.toJSON());
